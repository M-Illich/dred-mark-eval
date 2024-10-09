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

		int maxNodeNumber = 5;
		int numberOfUpdates = 3;

		// compute materialization with marking approach
		UpdateStreamRun usrMark = new UpdateStreamRun("dred_mark.pl", randomSeed, maxNodeNumber, numberOfUpdates);
		usrMark.execute(false, false, false);
		// compute materialization without marking
		UpdateStreamRun usrNoMark = new UpdateStreamRun("dred_no_mark.pl", randomSeed, maxNodeNumber, numberOfUpdates);
		usrNoMark.execute(false, false, false);

		for (int i = 0; i < usrMark.datasets.size(); i++) {
			// compute materialization for dataset from scratch
			SimpleMaterialization sm = new SimpleMaterialization(usrMark.datasets.get(i));

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
