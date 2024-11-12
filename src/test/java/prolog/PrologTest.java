package prolog;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.util.Random;
import java.util.Set;

import org.junit.Test;

import data.Fact;
import stream.SimpleMaterialization;
import stream.UpdateStreamRun;

public class PrologTest {

	@Test
	public void testProlog() {
		
		testProlog("dred_no_mark.pl", "dred_mark.pl", "dred_mark_only_negative.pl", "materialize.pl");
		testProlog("dred_no_mark_alt.pl", "dred_mark_alt.pl", "dred_mark_alt.pl", "materialize_alt.pl");
		

	}
	
	private void testProlog(String file1, String file2, String file3, String fileExpected) {
		// create random seed
				Random rnd = new Random();
				long randomSeed = rnd.nextLong();
				System.out.println("random seed: " + randomSeed);

				int maxNodeNumber = 10;
				int numberOfUpdates = 5;

				// compute materialization without marking
				UpdateStreamRun usrNoMark = new UpdateStreamRun(file1, randomSeed, maxNodeNumber, numberOfUpdates,
						0);
				usrNoMark.execute(false, false, false);

				// compute materialization with marking approach
				UpdateStreamRun usrMark = new UpdateStreamRun(file2, randomSeed, maxNodeNumber, numberOfUpdates, 0);
				usrMark.execute(false, false, false);

				// compute materialization with marking approach
				UpdateStreamRun usrMarkOnlyNegative = new UpdateStreamRun(file3, randomSeed, maxNodeNumber,
						numberOfUpdates, 0);
				usrMarkOnlyNegative.execute(false, false, false);

				for (int i = 0; i < usrMark.datasets.size(); i++) {
					// compute materialization for dataset from scratch
					SimpleMaterialization sm = new SimpleMaterialization(fileExpected, usrMark.datasets.get(i));

					// compare results with simple method
					Set<Fact> mat = sm.execute();
					assertEquals(mat.size(), usrMark.queryAnswers.get(i).size());
					assertTrue(mat.containsAll(usrMark.queryAnswers.get(i)));
					assertEquals(mat.size(), usrMarkOnlyNegative.queryAnswers.get(i).size());
					assertTrue(mat.containsAll(usrMarkOnlyNegative.queryAnswers.get(i)));
					// compare between with and without marking
					assertEquals(usrNoMark.queryAnswers.get(i).size(), usrMark.queryAnswers.get(i).size());
					assertTrue(usrNoMark.queryAnswers.get(i).containsAll(usrMark.queryAnswers.get(i)));
					assertEquals(usrMarkOnlyNegative.queryAnswers.get(i).size(), usrMark.queryAnswers.get(i).size());
					assertTrue(usrMarkOnlyNegative.queryAnswers.get(i).containsAll(usrMark.queryAnswers.get(i)));
				}
	}

}
