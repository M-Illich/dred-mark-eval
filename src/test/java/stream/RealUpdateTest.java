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
	File file0 = new File(updateFolder + "/01.pl");
	File file1 = new File(updateFolder + "/02.pl");
	RealUpdateStreamRun usr = new RealUpdateStreamRun("no_file", updateFolder);

	// facts occurring in test files
	Fact f1 = new Fact("nextInWay(1, 2, 1)");
	Fact f2 = new Fact("nextInWay(2, 3, 2)");
	Fact f3 = new Fact("nextInWay(3, 4, 3)");
	Fact f4 = new Fact("nextInWay(4, 5, 3)");
	
	// update sets
	Set<Fact> add0 = new HashSet<Fact>(Set.of(f1, f2, f3));
	Set<Fact> add1 = new HashSet<Fact>(Set.of(f4));
	Set<Fact> delete0 = new HashSet<Fact>();
	Set<Fact> delete1 = new HashSet<Fact>(Set.of(f1));

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
