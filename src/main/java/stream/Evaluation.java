package stream;

import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

public class Evaluation {

	/**
	 * number of repeated runs to compute average runtime
	 */
	final static int REPETITIONS = 5;

	/**
	 * "synthetic" or "real" tests are possible
	 */
	static String TEST_TYPE = "real"; // "synthetic"; //

	/**
	 * for "synthetic": 0 (transitive paths) or 1 (sequential renaming); for "real":
	 * 0 (GPS track0), 1 (GPS track1), or 2 (GPS track2)
	 */
	static int TEST_CASE = 2;

	/**
	 * index to choose random seed from array
	 */
	static int RND_SEED_INDEX = 0;

	/**
	 * random seeds used for synthetic "transitive path" tests
	 */
	static long[] RND_SEED_TRANS = new long[] { 0, -8530167300591734801l, -7052395318707035129l,
			-1747236591629776228l };

	/**
	 * random seeds used for synthetic "sequential renaming" tests
	 */
	static long[] RND_SEED_SEQ = new long[] { 0, -1286130758052520077l, 1844037384923181921l, -7987291794494113099l };

	public static void main(String[] args) throws Exception {

		if (args.length >= 2) {
			TEST_TYPE = args[0];
			TEST_CASE = Integer.parseInt(args[1]);
		}

		System.out.println("test type: " + TEST_TYPE + "  --  test case: " + TEST_CASE);

		if (TEST_TYPE.contentEquals("synthetic")) {
			// parameters for update stream
			int maxNodeNumber = 20;
			int initialDataSize = 100;
			int updateSize = 10;
			int numberOfUpdates = 50;
			int updateDelay = 0;
			int[] parameters = new int[] { maxNodeNumber, initialDataSize, updateSize, numberOfUpdates, updateDelay };
			String[] parameterNames = new String[] { "maxNodeNumber", "initialDataSize", "updateSize",
					"numberOfUpdates", "updateDelay" };

			/**
			 * index of parameter for which different, increasing values are considered
			 * during evaluation
			 */
			int variantIndex = 2;
			int variantStart = 10;
			int variantEnd = 80;
			int variantStep = 10;

			// determine random seed for update generation
			Random rnd = new Random();
			long randomSeed = rnd.nextLong();
			// add new random seed to predetermined ones
			RND_SEED_TRANS[0] = randomSeed;
			RND_SEED_SEQ[0] = randomSeed;
			// determine index to select random seed from array
			if (args.length == 3) {
				RND_SEED_INDEX = Integer.parseInt(args[2]);
			}
			if (RND_SEED_INDEX < 0 || RND_SEED_INDEX > 3) {
				throw new Exception("Invalid argument. Only 0, 1, 2, or 3 are allowed for random seed selection.");
			}

			// list of prolog files related to different test cases
			List<String> files = null;
			switch (TEST_CASE) {
			case 0:
				files = List.of("dred_no_mark_trans.pl", "dred_mark_trans.pl");
				randomSeed = RND_SEED_TRANS[RND_SEED_INDEX];
				break;

			case 1:
				files = List.of("dred_no_mark_seq.pl", "dred_mark_seq.pl");
				// maxNodeNumber = 100
				parameters[0] = 100;
				randomSeed = RND_SEED_SEQ[RND_SEED_INDEX];
				break;
			default:
				throw new Exception("Invalid test case. Only 0 or 1 are allowed for synthetic test");
			}

			System.out.println("random seed:" + randomSeed);

			for (String file : files) {
				performRandomEvaluation(file, randomSeed, parameters, parameterNames, variantIndex, variantStart,
						variantEnd, variantStep);
			}
		}

		else if (TEST_TYPE.contentEquals("real")) {
			if (TEST_CASE == 0 || TEST_CASE == 1 || TEST_CASE == 2) {
				String updateFolder = "src/main/resources/updates/filtered/updates_track" + TEST_CASE;
				List<String> filesReal = List.of("dred_no_mark_map.pl", "dred_mark_map.pl");
				for (String file : filesReal) {
					performRealEvaluation(file, updateFolder);
				}
			} else {
				throw new Exception("Invalid test case. Only 0, 1, or 2 are allowed for real test");
			}

		}
		// invalid test type
		else {
			throw new Exception("Invalid test type. Only \"synthetic\" or \"real\" are allowed.");
		}

	}

	/**
	 * Use the materialization maintenance approach implemented in {@code file} to
	 * process a randomly created stream of updates. A csv-file is created, which
	 * shows the cpu runtime, the number of applied rules for the overdeletion,
	 * rederivation and insertion phase, as well as the number of marked facts.
	 * 
	 * @param file           {@code String} name of Prolog file which contains the
	 *                       approach to be evaluated
	 * @param randomSeed     {@code long} enables random generation of updates
	 * @param parameters     {@code int[]} values for maxNodeNumber,
	 *                       initialDataSize, updateSize, numberOfUpdates,
	 *                       updateDelay of (see {@link UpdateStreamRun})
	 * @param parameterNames {@code String[]} names of parameters
	 * @param variantIndex   {@code int} index of parameter for which different,
	 *                       increasing values are considered during evaluation
	 * @param variantStart   {@code int} initial value of variant parameter
	 * @param variantEnd     {@code int} last/maximum value of variant parameter
	 * @param variantStep    {@code int} value used to increase variant each
	 *                       iteration
	 */
	public static void performRandomEvaluation(String file, long randomSeed, int[] parameters, String[] parameterNames,
			int variantIndex, int variantStart, int variantEnd, int variantStep) {

		String approach = file.substring(5, file.length() - 3);
		System.out.println(approach);

		PrintWriter writer;

		try {
			Files.createDirectories(Paths.get("results"));
			// store results as table in a file
			writer = new PrintWriter("results/results-" + approach + "-changing_" + parameterNames[variantIndex] + "_"
					+ randomSeed + ".csv", "UTF-8");
			// different statistics (used as columns for table in file)
			String categories = "runtime,appliedRules(del),appliedRules(red),appliedRules(ins),markedFacts(addEx),markedFacts(addIm),markedFacts(delEx),markedFacts(delIm)";
			String parameterNamesString = Arrays.toString(parameterNames).replaceAll(" ", "");
			parameterNamesString = parameterNamesString.substring(1, parameterNamesString.length() - 1);
			String parametersString = Arrays.toString(parameters).replaceAll(" ", "");
			parametersString = parametersString.substring(1, parametersString.length() - 1);

			writer.println(parameterNames[variantIndex] + "," + categories + "," + parameterNamesString);

			// perform evaluation for different parameter values
			for (int variant = variantStart; variant <= variantEnd; variant += variantStep) {
				System.out.println(parameterNames[variantIndex] + ": " + variant);

				parameters[variantIndex] = variant;

				// create update stream
				SyntheticUpdateStreamRun usr = new SyntheticUpdateStreamRun(file, randomSeed, parameters[0],
						parameters[1], parameters[2], parameters[3], parameters[4]);

				float avgCpuTime = 0;
				for (int i = 0; i < REPETITIONS; i++) {
					// process update stream
					usr.execute(false, false, false);
					avgCpuTime += usr.statistics.cpuTime;
				}

				// compute average runtime
				avgCpuTime = avgCpuTime / REPETITIONS;
				System.out.println("");
				System.out.println("average cpu time: " + avgCpuTime);
				System.out.println("");

				// get measured values from statistics
				String measures = variant + "," + avgCpuTime + "," + usr.statistics.appliedRules.get("del") + ","
						+ usr.statistics.appliedRules.get("red") + "," + usr.statistics.appliedRules.get("ins") + ","
						+ usr.statistics.markedFacts.get("addEx") + "," + usr.statistics.markedFacts.get("addIm") + ","
						+ usr.statistics.markedFacts.get("delEx") + "," + usr.statistics.markedFacts.get("delIm") + ","
						+ parametersString;

				// write statistics to file
				writer.println(measures);
			}

			writer.close();

		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Use the materialization maintenance approach implemented in {@code file} to
	 * process a stream of updates based on real-world data. A csv-file is created,
	 * which shows the cpu runtime, the number of applied rules for the
	 * overdeletion, rederivation and insertion phase, as well as the number of
	 * marked facts.
	 * 
	 * @param file         {@code String} name of file containing SWI-Prolog code to
	 *                     be executed
	 * @param updateFolder {@code String} name of folder where each stream update is
	 *                     stored as file
	 */
	public static void performRealEvaluation(String file, String updateFolder) {

		String approach = file.substring(5, file.length() - 3);
		String updatesName = updateFolder.substring(updateFolder.lastIndexOf("/") + 1);
		System.out.println(approach);

		PrintWriter writer;

		try {
			Files.createDirectories(Paths.get("results"));
			// store results as table in a file
			writer = new PrintWriter("results/results-" + approach + "-map_stream-" + updatesName + ".csv", "UTF-8");
			// different statistics (used as columns for table in file)
			String categories = "runtime,appliedRules(del),appliedRules(red),appliedRules(ins),markedFacts(addEx),markedFacts(addIm),markedFacts(delEx),markedFacts(delIm)";
			writer.println(categories);

			// create update stream
			RealUpdateStreamRun usr = new RealUpdateStreamRun(file, updateFolder);

			float avgCpuTime = 0;
			for (int i = 0; i < REPETITIONS; i++) {
				// process update stream
				usr.execute(false, false, false);
				avgCpuTime += usr.statistics.cpuTime;
			}

			// compute average runtime
			avgCpuTime = avgCpuTime / REPETITIONS;
			System.out.println("");
			System.out.println("average cpu time: " + avgCpuTime);
			System.out.println("");

			// get measured values from statistics
			String measures = avgCpuTime + "," + usr.statistics.appliedRules.get("del") + ","
					+ usr.statistics.appliedRules.get("red") + "," + usr.statistics.appliedRules.get("ins") + ","
					+ usr.statistics.markedFacts.get("addEx") + "," + usr.statistics.markedFacts.get("addIm") + ","
					+ usr.statistics.markedFacts.get("delEx") + "," + usr.statistics.markedFacts.get("delIm");

			// write statistics to file
			writer.println(measures);

			writer.close();

		} catch (Exception e) {
			e.printStackTrace();
		}
	}

}
