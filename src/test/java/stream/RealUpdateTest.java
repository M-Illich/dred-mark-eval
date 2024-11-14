package stream;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;
import java.util.Set;

import org.junit.Test;

import data.Fact;
import data.Update;

public class RealUpdateTest {

	String updateFolder = "src/test/resources/updates";
	File file1 = new File(updateFolder + "/1_facts_48.397762_9.984186_2024-08-10_09.23.45_100.pl");
	File file2 = new File(updateFolder + "/2_facts_48.397602_9.984297_2024-08-10_09.23.50_100.pl");
	RealUpdateStreamRun usr = new RealUpdateStreamRun("no_file", updateFolder, false);

	@Test
	public void testCreateUpdateStream() {

		File file = new File("src/test/resources/update_stream.txt");
		PrintWriter out;
		try {
			out = new PrintWriter(file);
			List<Set<Fact>> datasets = usr.createUpdateStream(out, false);

			// check explicit datasets
			Set<Fact> dataset1 = Set.of(new Fact("position(1)"), new Fact("node(1)"), new Fact("node(2)"));
			Set<Fact> dataset2 = Set.of(new Fact("position(2)"), new Fact("node(3)"), new Fact("node(2)"),
					new Fact("nodeTag(3, \"test\", \"yes\")"));

			assertEquals(dataset1.size(), datasets.get(0).size());
			assertTrue(dataset1.containsAll(datasets.get(0)));
			assertEquals(dataset2.size(), datasets.get(1).size());
			assertTrue(datasets.get(1).containsAll(dataset2));

			out.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

	}

	@Test
	public void testGetSeconds() {
		long time = usr.getTimeSeconds(file1);
		long expected = 9 * 3600 + 23 * 60 + 45;
		assertEquals(expected, time);
		assertEquals(5, usr.getTimeSeconds(file2) - time);

	}

	@Test
	public void testReadUpdate() {
		Set<Fact> added = Set.of(new Fact("position(2)"), new Fact("node(3)"), new Fact("nodeTag(3, \"test\", \"yes\")"));
		Set<Fact> deleted = Set.of(new Fact("position(1)"), new Fact("node(1)"));
		
		Update u = usr.readUpdate(file2);
		
		assertEquals(added.size(),u.added.size());
		assertTrue(added.containsAll(u.added));
		assertEquals(deleted.size(),u.deleted.size());
		assertTrue(deleted.containsAll(u.deleted));

	}

}
