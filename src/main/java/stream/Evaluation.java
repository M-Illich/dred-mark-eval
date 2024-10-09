package stream;

import java.util.List;

public class Evaluation {

	public static void main(String[] args) {

		long randomSeed = 123456;
		int maxNodeNumber = 10;
		int initialDataSize = 20;
		int updateSize = 5;
		int numberOfUpdates = 10;

		for (String file : List.of("dred_mark.pl", "dred_no_mark.pl")) {
			
			UpdateStreamRun usr = new UpdateStreamRun(file, randomSeed, maxNodeNumber, initialDataSize, updateSize,
					numberOfUpdates);

			float runtime = 0;
			int repetitions = 5;

			for (int i = 0; i < repetitions; i++) {
				usr.execute(false, false, false);
				runtime += usr.statistics.runtime;
			}

			// compute average runtime
			runtime = runtime / repetitions;

			System.out.println(file);
			System.out.println(runtime);
			System.out.println("");

		}
	}

}
