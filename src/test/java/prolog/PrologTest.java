package prolog;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.util.Random;
import java.util.Set;

import org.junit.Test;

import graph.Fact;
import stream.SimpleMaterialization;
import stream.UpdateStreamRun;

public class PrologTest {

	@Test
	public void testProlog() {

		// create random seed
		Random rnd = new Random();
		long randomSeed = rnd.nextLong();
		System.out.println("random seed: " + randomSeed);

		int maxNodeNumber = 10;
		int numberOfUpdates = 5;

		// compute materialization without marking
		UpdateStreamRun usrNoMark = new UpdateStreamRun("dred_no_mark.pl", randomSeed, maxNodeNumber, numberOfUpdates,
				0);
		usrNoMark.execute(false, false, false);

		// compute materialization with marking approach
		UpdateStreamRun usrMark = new UpdateStreamRun("dred_mark.pl", randomSeed, maxNodeNumber, numberOfUpdates, 0);
		usrMark.execute(false, false, false);

		// compute materialization with marking approach
		UpdateStreamRun usrMarkOnlyNegative = new UpdateStreamRun("dred_mark_only_negative.pl", randomSeed, maxNodeNumber,
				numberOfUpdates, 0);
		usrMarkOnlyNegative.execute(false, false, false);

		for (int i = 0; i < usrMark.datasets.size(); i++) {
			// compute materialization for dataset from scratch
			SimpleMaterialization sm = new SimpleMaterialization(usrMark.datasets.get(i));

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
