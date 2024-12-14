package stream;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.junit.Test;

import data.Fact;
import data.Update;

public class RealUpdateTest {

	String updateFolder = "src/test/resources/updates";
	File file0 = new File(updateFolder + "/00_facts_48.398621_9.984068_2024-08-10_09.23.33_100.pl");
	File file1 = new File(updateFolder + "/01_facts_48.397888_9.984138_2024-08-10_09.23.39_100.pl");
	RealUpdateStreamRun usr = new RealUpdateStreamRun("no_file", updateFolder);

	// facts occurring in test files
	Fact node1 = new Fact("node(1)");
	Fact node2 = new Fact("node(2)");
	Fact node3 = new Fact("node(3)");
	Fact node4 = new Fact("node(4)");
	Fact node5 = new Fact("node(5)");
	Fact node6 = new Fact("node(6)");
	Fact node7 = new Fact("node(7)");
	Fact node8 = new Fact("node(8)");
	Fact nodeTag1 = new Fact("nodeTag(1, \"highway\", \"give_way\")");
	Fact nodeTag2 = new Fact("nodeTag(2, \"highway\", \"stop\")");
	Fact nodeTag3 = new Fact("nodeTag(3, \"highway\", \"traffic_signals\")");
	Fact nodeTag4 = new Fact("nodeTag(4, \"highway\", \"crossing\")");
	Fact nodeTag5 = new Fact("nodeTag(5, \"highway\", \"tram_level_crossing\")");
	Fact nodeTag6 = new Fact("nodeTag(6, \"highway\", \"level_crossing\")");
	Fact nodeTag7a = new Fact("nodeTag(7, \"public_transport\", \"stop_position\")");
	Fact nodeTag7b = new Fact("nodeTag(7, \"bus\", \"yes\")");
	Fact nodeTag8a = new Fact("nodeTag(8, \"public_transport\", \"stop_position\")");
	Fact nodeTag8b = new Fact("nodeTag(8, \"tram\", \"yes\")");
	// update sets
	Set<Fact> add0 = new HashSet<Fact>(
			Set.of(node1, nodeTag1, node2, nodeTag2, node3, nodeTag3, node4, nodeTag4, node5, nodeTag5));
	Set<Fact> add1 = new HashSet<Fact>(
			Set.of(node6, nodeTag6, node7, nodeTag7a, nodeTag7b, node8, nodeTag8a, nodeTag8b));
	Set<Fact> delete0 = new HashSet<Fact>();
	Set<Fact> delete1 = new HashSet<Fact>(Set.of(node1, nodeTag1, node2, nodeTag2, node3, nodeTag3));

	@Test
	public void testCreateUpdateStream() {

		File file = new File("src/test/resources/update_stream.txt");
		PrintWriter out;
		try {
			out = new PrintWriter(file);
			List<Set<Fact>> datasets = usr.createUpdateStream(out, false);

			assertEquals(add0.size(), datasets.get(0).size());
			assertTrue(add0.containsAll(datasets.get(0)));

			Set<Fact> dataset2 = new HashSet<>(add0);
			dataset2.addAll(add1);
			dataset2.removeAll(delete1);

			assertEquals(dataset2.size(), datasets.get(1).size());
			assertTrue(datasets.get(1).containsAll(dataset2));

			out.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

	}

	

	@Test
	public void testReadUpdate() {
		Update u = usr.readUpdate(file1);

		assertEquals(add1.size(), u.added.size());
		assertTrue(add1.containsAll(u.added));
		assertEquals(delete1.size(), u.deleted.size());
		assertTrue(delete1.containsAll(u.deleted));

	}


}
