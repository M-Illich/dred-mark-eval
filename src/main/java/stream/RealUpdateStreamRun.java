package stream;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

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
	 * @param realDelay    {@code boolean} stating if there should be a delay
	 *                     between updates based on real GPS time points
	 */
	public RealUpdateStreamRun(String file, String updateFolder, boolean realDelay) {
		this.file = file;
		this.updateFolder = updateFolder;
		this.realDelay = realDelay;
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

			// delay stream according to GPS point time
			if (realDelay) {
				try {
					if (i == 1) {
						System.out.print("update delay [sec]: ");
					} else {
						long delay = getTimeSeconds(updateFiles[i - 1]) - getTimeSeconds(updateFiles[i - 2]);
						System.out.print(delay + " ");
						TimeUnit.SECONDS.sleep(delay);
					}
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				if (i == updateFiles.length) {
					System.out.println();
				}

			}

			// write update to stream (if not empty)
			if (!(u.added.isEmpty() && u.deleted.isEmpty())) {
				out.println(u.added.toString());
				out.println(u.deleted.toString());
			}

			if (printUpdates) {
				// there is a query directly after each update (asking for every fact)
				System.out.println("query " + i);
			}

		}

		// indicate end of stream
		out.println("[]");
		out.println("[]");

		return datasets;

	}

	/**
	 * Get time in seconds that is stated in the name of the file in the format
	 * {@code HH.MM.SS}.
	 * 
	 * @param file a {@link File} containing an update, where name is similar to
	 *             {@code 1_facts_48.397762_9.984186_2024-08-10_09.23.45_100.pl}
	 * @return {@code long} seconds
	 */
	long getTimeSeconds(File file) {
		String name = file.getName();
		String timeString = name.substring(name.lastIndexOf("_") - 8, name.lastIndexOf("_"));

		// time format = "HH.MM.SS"
		long hours = Long.valueOf(timeString.substring(0, 2));
		long min = Long.valueOf(timeString.substring(3, 5));
		long sec = Long.valueOf(timeString.substring(6));
		long seconds = hours * 3600 + min * 60 + sec;

		return seconds;
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
					String fact = line.substring(4, line.length() - 2);
					if (filteredFact(fact)) {
						addFacts.add(new Fact(fact));
					}
				} else if (line.startsWith("delete(")) {
					String fact = line.substring(7, line.length() - 2);
					if (filteredFact(fact)) {
						deleteFacts.add(new Fact(fact));
					}
				}
				line = reader.readLine();
			}

			// only keep node and way fats that actually have relevant tags
			addFacts = keepTaggedFacts(addFacts);
			deleteFacts = keepTaggedFacts(deleteFacts);

			reader.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

		return new Update(addFacts, deleteFacts);

	}

	/**
	 * 
	 * @param fact {@code String} describing a Datalog fact
	 * @return {@code true} if {@code fact} can be matched to rules that are used
	 *         for evaluation with real data
	 */
	boolean filteredFact(String fact) {
		if (fact.startsWith("node(")) {
			return true;
		} else if (fact.startsWith("nodeTag(")) {
			if (fact.contains("highway")) {
				if (fact.contains("give_way") || fact.contains("stop") || fact.contains("traffic_signals")
						|| fact.contains("crossing") || fact.contains("tram_level_crossing")
						|| fact.contains("level_crossing")) {
					return true;
				}
			} else if (fact.contains("public_transport") && fact.contains("stop_position")) {
				return true;
			} else if ((fact.contains("bus") || fact.contains("tram")) && fact.contains("yes")) {
				return true;
			}
		} else if (fact.startsWith("way(")) {
			return true;
		} else if (fact.startsWith("wayTag(")) {
			if (fact.contains("amenity") && (fact.contains("kindergarten") || fact.contains("school"))) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Only keep {@code node} and {@code way} facts for which there exist
	 * {@code nodeTag} or {@code wayTag} facts in {@code set}
	 * 
	 * @param set {@link Set} of {@link Fact} elements representing OSM facts
	 * @return {@code set} without any non-tagged facts
	 */
	Set<Fact> keepTaggedFacts(Set<Fact> set) {
		Set<Fact> filteredSet = new HashSet<>(set);
		for (Fact fact : set) {
			if (fact.predicate.equals("node") || fact.predicate.equals("way")) {
				// get ID
				String id = fact.arguments.getFirst();

				// only keep fact if there exist tags for ID
				boolean noTag = true;
				for (Fact fact2 : set) {
					if (fact2.predicate.contains("Tag") && fact2.arguments.contains(id)) {
						noTag = false;
						break;
					}
				}
				if (noTag) {
					filteredSet.remove(fact);
				}
			}
		}
		return filteredSet;
	}

}
