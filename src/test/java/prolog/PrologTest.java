package prolog;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.File;
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
		
		System.out.println("Synthetic test 1");
		testSyntheticProlog("dred_no_mark.pl", "dred_mark.pl", "dred_mark_only_negative.pl", "materialize.pl");
		System.out.println("");
		System.out.println("Synthetic test 2");
		testSyntheticProlog("dred_no_mark_alt.pl", "dred_mark_alt.pl", null, "materialize_alt.pl");
		System.out.println("");
		System.out.println("Real test");
		testRealProlog("dred_no_mark_osm.pl", "dred_mark_osm.pl", "materialize_osm.pl");

	}

	private void testSyntheticProlog(String file1, String file2, String file3, String fileExpected) {
		// create random seed
		Random rnd = new Random();
		long randomSeed = rnd.nextLong();
		System.out.println("random seed: " + randomSeed);

		int maxNodeNumber = 10;
		int numberOfUpdates = 5;

		// compute materialization without marking
		UpdateStreamRun usrNoMark = new SyntheticUpdateStreamRun(file1, randomSeed, maxNodeNumber, numberOfUpdates, 0);
		usrNoMark.execute(false, false, false);

		// compute materialization with marking approach
		UpdateStreamRun usrMark = new SyntheticUpdateStreamRun(file2, randomSeed, maxNodeNumber, numberOfUpdates, 0);
		usrMark.execute(false, false, false);

		// compute materialization with marking approach
		UpdateStreamRun usrMarkOnlyNegative = null;
		if (file3 != null) {
			usrMarkOnlyNegative = new SyntheticUpdateStreamRun(file3, randomSeed, maxNodeNumber, numberOfUpdates, 0);
			usrMarkOnlyNegative.execute(false, false, false);
		}

		assertEquals(numberOfUpdates, usrNoMark.queryAnswers.size());
		assertEquals(numberOfUpdates, usrMark.queryAnswers.size());

		if (usrMarkOnlyNegative != null) {
			assertEquals(numberOfUpdates, usrMarkOnlyNegative.queryAnswers.size());
		}

		for (int i = 0; i < usrMark.datasets.size(); i++) {
			// compute materialization for dataset from scratch
			SimpleMaterialization sm = new SimpleMaterialization(fileExpected, usrMark.datasets.get(i));

			// compare results with simple method
			Set<Fact> mat = sm.execute();
			assertEquals(mat.size(), usrMark.queryAnswers.get(i).size());
			assertTrue(mat.containsAll(usrMark.queryAnswers.get(i)));
			if (usrMarkOnlyNegative != null) {
				assertEquals(mat.size(), usrMarkOnlyNegative.queryAnswers.get(i).size());
				assertTrue(mat.containsAll(usrMarkOnlyNegative.queryAnswers.get(i)));
			}

			// compare between with and without marking
			assertEquals(usrNoMark.queryAnswers.get(i).size(), usrMark.queryAnswers.get(i).size());
			assertTrue(usrNoMark.queryAnswers.get(i).containsAll(usrMark.queryAnswers.get(i)));
			if (usrMarkOnlyNegative != null) {
				assertEquals(usrMarkOnlyNegative.queryAnswers.get(i).size(), usrMark.queryAnswers.get(i).size());
				assertTrue(usrMarkOnlyNegative.queryAnswers.get(i).containsAll(usrMark.queryAnswers.get(i)));
			}

		}
	}

	private void testRealProlog(String file1, String file2, String fileExpected) {

		String updateFolder = "src/test/resources/real_updates";

		// compute materialization without marking
		UpdateStreamRun usrNoMark = new RealUpdateStreamRun(file1, updateFolder, false);
		usrNoMark.execute(false, false, true);

		// compute materialization with marking approach
		UpdateStreamRun usrMark = new RealUpdateStreamRun(file2, updateFolder, false);
		usrMark.execute(false, false, true);	// TODO

		assertEquals(new File(updateFolder).listFiles().length, usrNoMark.queryAnswers.size());
		assertEquals(new File(updateFolder).listFiles().length, usrMark.queryAnswers.size());

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
