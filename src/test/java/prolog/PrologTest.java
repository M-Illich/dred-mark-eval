package prolog;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.util.HashSet;
import java.util.Random;
import java.util.Set;

import org.junit.Test;

import data.Fact;
import stream.RealUpdateStreamRun;
import stream.SimpleMaterialization;
import stream.SyntheticUpdateStreamRun;
import stream.UpdateStreamRun;

public class PrologTest {

	@Test
	public void testProlog() {

		System.out.println("Synthetic test 1 - DRed");
		testSyntheticProlog("dred/dred_no_mark_trans.pl", "dred/dred_mark_trans.pl", "materialize_trans.pl");
		System.out.println("Synthetic test 1 - B/F");
		testSyntheticProlog("bf/bf_no_mark_trans.pl", "bf/bf_mark_trans.pl", "materialize_trans.pl");
		System.out.println("");
		System.out.println("Synthetic test 2 - DRed");
		testSyntheticProlog("dred/dred_no_mark_seq.pl", "dred/dred_mark_seq.pl", "materialize_seq.pl");
		System.out.println("Synthetic test 2 - B/F");
		testSyntheticProlog("bf/bf_no_mark_seq.pl", "bf/bf_mark_seq.pl", "materialize_seq.pl");
		System.out.println("");
		System.out.println("Real test - DRed");
		testRealProlog("dred/dred_no_mark_map.pl", "dred/dred_mark_map.pl", "materialize_map.pl");
		System.out.println("Real test - B/F");
		testRealProlog("bf/bf_no_mark_map.pl", "bf/bf_mark_map.pl", "materialize_map.pl");

	}

	private void testSyntheticProlog(String file1, String file2, String fileExpected) {
		// create random seed
		Random rnd = new Random();
		long randomSeed = rnd.nextLong();
		System.out.println("random seed: " + randomSeed);

		int maxNodeNumber = 10;
		int numberOfUpdates = 10;

		// compute materialization without marking
		UpdateStreamRun usrNoMark = new SyntheticUpdateStreamRun(file1, randomSeed, maxNodeNumber, numberOfUpdates, 0);
		usrNoMark.execute(false, false, false);

		// compute materialization with marking approach
		UpdateStreamRun usrMark = new SyntheticUpdateStreamRun(file2, randomSeed, maxNodeNumber, numberOfUpdates, 0);
		usrMark.execute(false, false, false);

		// compute materialization with marking approach
		assertEquals(numberOfUpdates, usrNoMark.queryAnswers.size());
		assertEquals(numberOfUpdates, usrMark.queryAnswers.size());

		for (int i = 0; i < usrMark.datasets.size(); i++) {
			// compute materialization for dataset from scratch
			SimpleMaterialization sm = new SimpleMaterialization(fileExpected, usrMark.datasets.get(i));

			// compare results with simple method
			Set<Fact> mat = sm.execute();
			// detect differences
			HashSet<Fact> diff = new HashSet<>();
			if (mat.size() < usrMark.queryAnswers.get(i).size()) {
				diff.addAll(usrMark.queryAnswers.get(i));
				diff.removeAll(mat);
			} else {
				diff.addAll(mat);
				diff.removeAll(usrMark.queryAnswers.get(i));
			}

			for (Fact fact : diff) {
				System.out.println("diff: " + fact);
			}

			assertEquals(mat.size(), usrMark.queryAnswers.get(i).size());
			assertTrue(mat.containsAll(usrMark.queryAnswers.get(i)));

			// compare between with and without marking
			assertEquals(usrMark.queryAnswers.get(i).size(), usrNoMark.queryAnswers.get(i).size());
			assertTrue(usrMark.queryAnswers.get(i).containsAll(usrNoMark.queryAnswers.get(i)));

		}
	}

	private void testRealProlog(String file1, String file2, String fileExpected) {

		String updateFolder = "src/test/resources/updates";
		int numberOfUpdates = 5;

		// compute materialization without marking
		UpdateStreamRun usrNoMark = new RealUpdateStreamRun(file1, updateFolder);
		usrNoMark.execute(false, false, false);

		// compute materialization with marking approach
		UpdateStreamRun usrMark = new RealUpdateStreamRun(file2, updateFolder);
		usrMark.execute(false, false, false);

		// compute materialization with marking approach
		assertEquals(numberOfUpdates, usrNoMark.queryAnswers.size());
		assertEquals(numberOfUpdates, usrMark.queryAnswers.size());

		for (int i = 0; i < usrMark.datasets.size(); i++) {
			// compute materialization for dataset from scratch
			SimpleMaterialization sm = new SimpleMaterialization(fileExpected, usrMark.datasets.get(i));

			// compare results with simple method
			Set<Fact> mat = sm.execute();
			assertEquals(mat.size(), usrMark.queryAnswers.get(i).size());
			assertTrue(mat.containsAll(usrMark.queryAnswers.get(i)));

			// compare between with and without marking
			assertEquals(usrNoMark.queryAnswers.get(i).size(), usrMark.queryAnswers.get(i).size());
			assertTrue(usrNoMark.queryAnswers.get(i).containsAll(usrMark.queryAnswers.get(i)));

		}
	}

}
