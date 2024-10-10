package stream;

import java.io.PrintWriter;
import java.util.List;
import java.util.Random;

public class Evaluation {

	public static void main(String[] args) {

		Random rnd = new Random();
		long randomSeed = rnd.nextLong();
		System.out.println("random seed:" + randomSeed);

		/*
		 * random seeds: -2952287021128233795 with maxNode = 20, initial = 100, updates
		 * = 10, size = 10-100
		 * 
		 * recommendation: keep number of updates high
		 */

		int maxNodeNumber = 10;
		int initialDataSize = 20;
		int updateSize = 5;
		int numberOfUpdates = 1000;

		int repetitions = 5;

		PrintWriter writer;

		for (String file : List.of("dred_mark.pl", "dred_no_mark.pl")) {

			String approach = file.substring(5, file.length() - 3);
			System.out.println(approach);

			try {
				// store results as table in a file
				writer = new PrintWriter("results-" + approach + ".csv", "UTF-8");
				// different statistics (used as columns for table in file)
				String categories = "runtime,appliedRules(del),appliedRules(red),appliedRules(ins),markedFacts(addEx),markedFacts(addIm),markedFacts(delEx),markedFacts(delIm)";
				writer.println("updateSize," + categories);

				// perform evaluation for different update sizes
				for (updateSize = 10; updateSize <= initialDataSize; updateSize += 10) {
					System.out.println("update size: " + updateSize);

					// create update stream
					UpdateStreamRun usr = new UpdateStreamRun(file, randomSeed, maxNodeNumber, initialDataSize,
							updateSize, numberOfUpdates);

					float avgRuntime = 0;
					for (int i = 0; i < repetitions; i++) {
						// process update stream
						usr.execute(false, false, false);
						avgRuntime += usr.statistics.runtime;
					}

					// compute average runtime
					avgRuntime = avgRuntime / repetitions;

					System.out.println("average runtime: " + avgRuntime);

					// get measured values from statistics
					String measures = updateSize + "," + avgRuntime + "," + usr.statistics.appliedRules.get("del") + ","
							+ usr.statistics.appliedRules.get("red") + "," + usr.statistics.appliedRules.get("ins")
							+ "," + usr.statistics.markedFacts.get("addEx") + ","
							+ usr.statistics.markedFacts.get("addIm") + "," + usr.statistics.markedFacts.get("delEx")
							+ "," + usr.statistics.markedFacts.get("delIm");

					// write statistics to file
					writer.println(measures);
				}

				writer.close();

			} catch (Exception e) {
				e.printStackTrace();
			}

		}

	}

}
