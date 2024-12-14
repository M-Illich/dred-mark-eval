package data;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;

public class OSMFilter {

	// folder where original, non-filtered updates are stored
	static String UPDATE_FOLDER = "src/main/resources/updates/original/updates50-";
	// folder where filtered updates will be stored
	static String FILTERED_FOLDER = "src/main/resources/updates/filtered/updates_track";

	public static void main(String[] args) {
		for (int i = 0; i < 3; i++) {
			filterUpdates(i);
		}
	}

	public static void filterUpdates(int track) {

		// create stream based on updates stored as files
		File[] updateFiles = new File(UPDATE_FOLDER + track).listFiles();
		// create folder for filtered updates
		String specificFilteredFolder = FILTERED_FOLDER + track + "/";
		try {
			Files.createDirectories(Paths.get(specificFilteredFolder));
		} catch (IOException e) {
			e.printStackTrace();
		}

		// count number of non-empty updates
		int noNull = 0;

		for (int i = 0; i < updateFiles.length; i++) {

			Set<Fact> addFacts = new HashSet<>();
			Set<Fact> deleteFacts = new HashSet<>();

			BufferedReader reader;
			try {
				reader = new BufferedReader(new FileReader(updateFiles[i]));
				String line = reader.readLine();

				while (line != null) {
					if (line.startsWith("add(")) {
						// extract actual fact from string
						String fact = line.substring(4, line.length() - 2);
						if (filteredFact(fact, track)) {
							addFacts.add(new Fact(fact));
						}
					} else if (line.startsWith("delete(")) {
						// extract actual fact from string
						String fact = line.substring(7, line.length() - 2);
						if (filteredFact(fact, track)) {
							deleteFacts.add(new Fact(fact));
						}
					}
					line = reader.readLine();
				}

				// only keep facts that relate to filtered wayTag-facts
				addFacts = keepRelatedFacts(addFacts);
				deleteFacts = keepRelatedFacts(deleteFacts);

				reader.close();

			} catch (Exception e) {
				e.printStackTrace();
			}

			Update u = new Update(addFacts, deleteFacts);

			if (!(u.added.isEmpty() && u.deleted.isEmpty())) {
				noNull++;
				u.writeToFile(specificFilteredFolder + String.format("%03d", noNull) + ".pl");
			}

		}

	}

	/**
	 * Only keep {@code NextInWay}-facts and certain {@code wayTag}-facts
	 * 
	 * @param fact  {@code String} describing a Datalog fact
	 * @param track {@code int} stating the currently considered, predefined GPS
	 *              track
	 * @return {@code true} if {@code fact} satisfies filter conditions, else
	 *         {@code false}
	 */
	static boolean filteredFact(String fact, int track) {
		if (fact.startsWith("nextInWay(")) {
			return true;
		} else if (fact.startsWith("wayTag(")) {
			switch (track) {
			case 0:
				if (fact.contains("footway")) {
					return true;
				}
				break;

			case 1:
				if (fact.contains("cycle")) {
					return true;
				}
				break;

			case 2:
				if (fact.contains("highway")) {
					Set<String> allowedTags = Set.of("secondary", "tertiary", "secondary_link", "tertiary_link");
					String tag = fact.substring(fact.lastIndexOf(",") + 3, fact.length() - 2);
					if (allowedTags.contains(tag)) {
						return true;
					}
				}
			}
		}

		return false;

	}

	/**
	 * Only keep {@code nextInWay} facts for which there exists a {@code wayTag}
	 * fact in {@code set}
	 * 
	 * @param set {@link Set} of {@link Fact} elements representing OSM facts
	 * @return {@code set} without any non-tagged facts
	 */
	static Set<Fact> keepRelatedFacts(Set<Fact> set) {
		Set<Fact> filteredSet = new HashSet<>(set);

		Set<Fact> wayTags = new HashSet<>();

		for (Fact fact : set) {
			boolean remove = true;
			if (fact.predicate.equals("nextInWay")) {
				String wayID = fact.arguments.getLast();
				for (Fact fact2 : set) {
					if (fact2.predicate.equals("wayTag") && fact2.arguments.getFirst().equals(wayID)) {
						remove = false;
						break;
					}
				}
			}
			if (fact.predicate.equals("wayTag")) {
				remove = false;
				wayTags.add(fact);
			}
			if (remove) {
				filteredSet.remove(fact);
			}
		}

		// only keep remaining nextInWay-facts
		filteredSet.removeAll(wayTags);

		return filteredSet;
	}

}
