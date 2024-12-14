package stream;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

import data.Fact;
import data.Update;

public class RealUpdateStreamRun extends UpdateStreamRun {

	/**
	 * name of folder where each stream update is stored as file
	 */
	String updateFolder;

	/**
	 * states if there should be a delay between updates based on real GPS time
	 * points
	 */
	boolean realDelay;

	/**
	 * 
	 * @param file         {@code String} name of file containing SWI-Prolog code to
	 *                     be executed
	 * @param updateFolder {@code String} name of folder where each stream update is
	 *                     stored as file
	 */
	public RealUpdateStreamRun(String file, String updateFolder) {
		this.file = file;
		this.updateFolder = updateFolder;
		this.statistics = new Statistics();

	}

	/**
	 * Create a stream based on the predefined updates in {@code updateFolder}. A
	 * query asking for every fact is stated after each update.
	 * 
	 * 
	 * @param out          {@link PrintWriter} to write updates to stream
	 * @param printUpdates {@code boolean} states if updates and their overlap with
	 *                     direct predecessor are printed to standard output
	 * @return a list of sets of facts representing the sequence of datasets created
	 *         by the update stream
	 */
	List<Set<Fact>> createUpdateStream(PrintWriter out, boolean printUpdates) {

		List<Set<Fact>> datasets = new LinkedList<>();
		Set<Fact> dataset = new HashSet<>();

		// store previous update to compute overlap
		Update pre = new Update(new HashSet<>(), new HashSet<>());
		HashSet<Fact> replaced_del = new HashSet<>();
		HashSet<Fact> replaced_add = new HashSet<>();
		Update u;

		// create stream based on updates stored as files
		File[] updateFiles = new File(updateFolder).listFiles();

		// collect statistics about number of changed facts
		int maxAdd = 0;
		int maxDel = 0;
		int sumAdd = 0;
		int sumDel = 0;
		int noNull = 0;

		for (int i = 1; i <= updateFiles.length; i++) {
			// read update from file
			u = readUpdate(updateFiles[i - 1]);

			// store updated explicit dataset
			dataset.addAll(u.added);
			dataset.removeAll(u.deleted);
			datasets.add(new HashSet<Fact>(dataset));

			if (printUpdates) {
				replaced_del.clear();
				replaced_add.clear();
				// determine overlap with previous update
				for (Fact fact : u.added) {
					if (pre.deleted.contains(fact)) {
						replaced_del.add(fact);
					}
				}
				for (Fact fact : u.deleted) {
					if (pre.added.contains(fact)) {
						replaced_add.add(fact);
					}
				}
				// store current update for next overlap
				pre = u;

				// print update
				System.out.println("");
				String[] us = u.toString().split("]:");
				System.out.println(i + ": " + us[0] + "]");
				System.out.println("    " + us[1]);
				// print size of overlap with previous update
				System.out.println(" Overlap with previous: replaced del = " + replaced_del.size()
						+ " - replaced add = " + replaced_add.size());
			}

			// write update to stream (if not empty)
			if (!(u.added.isEmpty() && u.deleted.isEmpty())) {
				out.println(u.added.toString());
				out.println(u.deleted.toString());

				// collect statistics about number of changed facts
				noNull++;
				sumAdd += u.added.size();
				sumDel += u.deleted.size();
				if (u.added.size() > maxAdd) {
					maxAdd = u.added.size();
				}
				if (u.deleted.size() > maxDel) {
					maxDel = u.deleted.size();
				}

			}

//			System.out.println(i + " add: " + u.added.size() + "  --  del: " + u.deleted.size());

			if (printUpdates) {
				// there is a query directly after each update (asking for every fact)
				System.out.println("query " + i);
			}
		}

		// indicate end of stream
		out.println("[]");
		out.println("[]");

		System.out.println("maxAdd: " + maxAdd + "  --  maxDel: " + maxDel + "  --  avgAdd: " + (sumAdd / noNull)
				+ "  --  avgDel: " + (sumDel / noNull) + "  --  updates: " + noNull);

		return datasets;

	}

	/**
	 * Create an update based on a file that explicitly states which facts have to
	 * be added and deleted.
	 * 
	 * @param file {@link File} containing in each line either
	 *             {@code add(p(a1, a2))} or {@code delete(p(a1, a2))} for any
	 *             Datalog fact {@code p(a2, a2)}
	 * @return {@link Update} with {@code add} and {@code delete} sets based on file
	 */
	Update readUpdate(File file) {

		Set<Fact> addFacts = new HashSet<>();
		Set<Fact> deleteFacts = new HashSet<>();

		BufferedReader reader;
		try {
			reader = new BufferedReader(new FileReader(file));
			String line = reader.readLine();

			while (line != null) {
				if (line.startsWith("add(")) {
					addFacts.add(new Fact(line.substring(4, line.length() - 2)));
				} else if (line.startsWith("delete(")) {
					deleteFacts.add(new Fact(line.substring(7, line.length() - 2)));
				}
				line = reader.readLine();
			}

			reader.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

		return new Update(addFacts, deleteFacts);

	}

}
