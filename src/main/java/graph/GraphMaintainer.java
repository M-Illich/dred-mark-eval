package graph;

import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;

public class GraphMaintainer {

	/*
	 * rules: edge --> path edge, path --> transitive path
	 * 
	 * randomly add + delete edges
	 */

	/**
	 * maximum number of nodes (values for edge arguments) in the graph
	 */
	int maxNodeNumber;

	// random number generator
	Random rndm;

	/**
	 * set of all the facts that were introduced by updates so far
	 */
	HashSet<Fact> addedFacts;

	public GraphMaintainer(int maxNodeNumber, long randomSeed) {
		this.maxNodeNumber = maxNodeNumber;
		rndm = new Random(randomSeed);
		addedFacts = new HashSet<>();
	}

	/**
	 * 
	 * @return set of facts that are explicitly present in current dataset, i.e.,
	 *         facts that were added by updates so far without the ones that were
	 *         already deleted
	 */
	public Set<Fact> getCurrentDataset() {
		return new HashSet<>(addedFacts);
	}

	/**
	 * @param num_add number of facts to be added
	 * @param num_del number of facts to be deleted
	 * @return an {@link Update} instance with edges of the form {@code edge(1,2)}
	 *         as {@link Fact} instances
	 */
	public Update createUpdate(int num_add, int num_del) {
		Set<Fact> add = createAdd(num_add);
		Set<Fact> delete = createDelete(num_del);

		// update addedFacts
		addedFacts.addAll(add);
		addedFacts.removeAll(delete);

		return new Update(add, delete);
	}

	/**
	 * 
	 * @return a random {@link Update} instance with edges of the form
	 *         {@code edge(1,2)} as {@link Fact} instances
	 */
	public Update createUpdateRandom() {
		Set<Fact> add = new HashSet<>();
		Set<Fact> delete = new HashSet<>();

		// decide if add (0), delete (1) or both (2)
		int choice = 0;
		// only delete facts that were previously added
		if (!addedFacts.isEmpty()) {
			// check if every possible fact already created
			if (addedFacts.size() == maxNodeNumber * maxNodeNumber) {
				choice = 1;
			} else {
				choice = rndm.nextInt(3);
			}
		}
		switch (choice) {
		case 0: {
			add = createAddRandom();
			break;
		}
		case 1: {
			delete = createDeleteRandom();
			break;
		}
		case 2: {
			add = createAddRandom();
			delete = createDeleteRandom();
		}
		}
		// update addedFacts
		addedFacts.addAll(add);
		addedFacts.removeAll(delete);

		return new Update(add, delete);
	}

	/**
	 * Create random set of edges as facts that are currently not present in the set
	 * of added facts {@code addedFacts}
	 * 
	 * @return random set of {@link Fact} instances representing edges in the form
	 *         of {@code edge(1,2)}
	 */
	private Set<Fact> createAddRandom() {
		// get number of edges that can still be created
		int available_num = maxNodeNumber * maxNodeNumber - addedFacts.size();
		// decide number of facts
		int num = rndm.nextInt(available_num) + 1;

		return createAdd(num);

	}

	/**
	 * Create set of edges as facts that are currently not present in the set of
	 * added facts {@code addedFacts}
	 * 
	 * @param num size of wanted set
	 * 
	 * @return random set of {@link Fact} instances representing edges in the form
	 *         of {@code edge(1,2)}
	 */
	private Set<Fact> createAdd(int num) {

		// define facts
		Set<Fact> facts = new HashSet<>();
		for (int i = 0; i < num; i++) {
			// create edge between two random facts
			Fact fact;
			do {
				int x = rndm.nextInt(maxNodeNumber);
				int y = rndm.nextInt(maxNodeNumber);

				// no edge to oneself
//				while (x == y) {
//					y = rndm.nextInt(maxNodeNumber);
//				}

				fact = new Fact("edge", List.of(x + "", y + ""));
			} // only add new fact
			while (addedFacts.contains(fact));
			facts.add(fact);
		}

		return facts;

	}

	/**
	 * Select random set of edges as facts that are present in the set of added
	 * facts {@code addedFacts}
	 * 
	 * @return random set of {@link Fact} instances representing edges in the form
	 *         of {@code edge(1,2)}
	 */
	private Set<Fact> createDeleteRandom() {
		// decide number of facts
		int num = rndm.nextInt(addedFacts.size()) + 1;
		// choose facts
		return createDelete(num);

	}

	/**
	 * Select a set of edges as facts that are present in the set of added facts
	 * {@code addedFacts}
	 * 
	 * @param num size of set
	 * 
	 * @return random set of {@link Fact} instances representing edges in the form
	 *         of {@code edge(1,2)}
	 */
	private Set<Fact> createDelete(int num) {
		// choose facts
		return new HashSet<>(addedFacts.stream().limit(num).toList());
	}

}
