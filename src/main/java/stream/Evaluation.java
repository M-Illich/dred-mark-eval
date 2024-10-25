package stream;

import java.io.PrintWriter;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.Set;

import graph.Fact;

public class Evaluation {

	/**
	 * number of repeated runs to compute average runtime
	 */
	final static int REPETITIONS = 3; // TODO

	public static void main(String[] args) {

		/*
		 * recommendation: keep number of updates high
		 * 
		 * random seeds: -2952287021128233795 with maxNode = 20, initial = 100, updates
		 * = 100, size = 10-100
		 * 
		 * -1005128985613677429l 928174635l 2487642182737836315l
		 * 
		 * -4429514994751527719 test for U = 10 and increasing number of updates
		 * 
		 * 
		 */

		Random rnd = new Random();
		long randomSeed = rnd.nextLong();
//		randomSeed = -4429514994751527719l;
		System.out.println("random seed:" + randomSeed);

		// parameters for update stream
		int maxNodeNumber = 20;
		int initialDataSize = 100;
		int updateSize = 10;
		int numberOfUpdates = 100;
		int updateDelay = 0;
		int[] parameters = new int[] { maxNodeNumber, initialDataSize, updateSize, numberOfUpdates, updateDelay };
		String[] parameterNames = new String[] { "maxNodeNumber", "initialDataSize", "updateSize", "numberOfUpdates",
				"updateDelay" };

		/**
		 * index of parameter for which different, increasing values are considered
		 * during evaluation
		 */
		int variantIndex = 2;
		int variantStart = 10;
		int variantEnd = 90;
		int variantStep = 10;

//		List<String> files = List.of("dred_no_mark.pl", "dred_mark.pl", "dred_mark_only_negative.pl");
		List<String> files = List.of("dred_no_mark_alt.pl", "dred_mark_alt.pl");
		for (String file : files) {
			performEvaluation(file, randomSeed, parameters, parameterNames, variantIndex, variantStart, variantEnd,
					variantStep);
		}

	}

	/**
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
	public static void performEvaluation(String file, long randomSeed, int[] parameters, String[] parameterNames,
			int variantIndex, int variantStart, int variantEnd, int variantStep) {

		String approach = file.substring(5, file.length() - 3);
		System.out.println(approach);

		PrintWriter writer;

		try {
			// store results as table in a file
			writer = new PrintWriter(
					"results-" + approach + "-" + parameterNames[variantIndex] + "_" + randomSeed + ".csv", "UTF-8");
			// different statistics (used as columns for table in file)
			String categories = "runtime,appliedRules(del),appliedRules(red),appliedRules(ins),markedFacts(addEx),markedFacts(addIm),markedFacts(delEx),markedFacts(delIm)";
			String parameterNamesString = Arrays.toString(parameterNames).replaceAll(" ", "");
			parameterNamesString = parameterNamesString.substring(1, parameterNamesString.length() - 1);
			String parametersString = Arrays.toString(parameters).replaceAll(" ", "");
			parametersString = parametersString.substring(1, parametersString.length() - 1);

			writer.println(parameterNames[variantIndex] + "," + categories + "," + parameterNamesString);

			// perform evaluation for different update sizes
			for (int variant = variantStart; variant <= variantEnd; variant += variantStep) {
				System.out.println(parameterNames[variantIndex] + ": " + variant);

				parameters[variantIndex] = variant;

				// create update stream
				UpdateStreamRun usr = new UpdateStreamRun(file, randomSeed, parameters[0], parameters[1], parameters[2],
						parameters[3], parameters[4]);

				float avgCpuTime = 0;
				for (int i = 0; i < REPETITIONS; i++) {
					// process update stream
					usr.execute(false, false, false);
					avgCpuTime += usr.statistics.cpuTime;
				}

				// TODO test
//				for (int i = 0; i < usr.datasets.size(); i++) {
//					// compute materialization for dataset from scratch
//					SimpleMaterialization sm = new SimpleMaterialization(usr.datasets.get(i));
//					// compare results with simple method
//					Set<Fact> mat = sm.execute();
//					boolean same = true;
//					if (usr.queryAnswers.get(i).size() != mat.size()) {
//						System.out.println("size: " + usr.queryAnswers.get(i).size() + " vs. expected: " + mat.size());
//						same = false;
//					}
//					for (Fact f : mat) {
//						if (!usr.queryAnswers.get(i).contains(f)) {
//							System.out.print(f.toString() + " ");
//							same = false;
//						}
//					}
//					if (!same) {
//						System.out.println("");
//						System.out.println("Not same result for i = " + i);
//						break;
//					}
//
//				}

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

}
