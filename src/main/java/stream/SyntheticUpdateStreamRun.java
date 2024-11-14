package stream;

import java.io.PrintWriter;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import data.Fact;
import data.GraphMaintainer;
import data.Update;

public class SyntheticUpdateStreamRun extends UpdateStreamRun {


	/**
	 * used to generate random updates
	 */
	long randomSeed;

	/**
	 * maximum number of nodes contained in randomly generated graph
	 */
	int maxNodeNumber;

	/**
	 * number of facts (edges) which are used to initialize the dataset (graph)
	 */
	int initialDataSize;

	/**
	 * number of facts added to and deleted from the dataset in each update
	 */
	int updateSize;

	/**
	 * length of update sequence provided in the stream
	 */
	int numberOfUpdates;

	/**
	 * waiting time (milliseconds) between updates in stream
	 */
	public int updateDelay;

	/**
	 * states if update size is fixed or chosen randomly
	 */
	boolean randomSize;

	/**
	 * Fixed update size.
	 * 
	 * @param file            {@code String} name of file containing SWI-Prolog code
	 *                        to be executed
	 * @param randomSeed      {@code long} used to generate random updates
	 * @param maxNodeNumber   {@code int} maximum number of nodes contained in
	 *                        randomly generated graph
	 * @param initialDataSize {@code int} number of facts (edges) which are used to
	 *                        initialize the dataset (graph)
	 * @param updateSize      {@code int} number of facts added to and deleted from
	 *                        the dataset in each update
	 * @param numberOfUpdates {@code int} length of update sequence provided in the
	 *                        stream
	 * @param updateDelay     {@code int} waiting time in milliseconds between
	 *                        updates in stream
	 */
	public SyntheticUpdateStreamRun(String file, long randomSeed, int maxNodeNumber, int initialDataSize,
			int updateSize, int numberOfUpdates, int updateDelay) {
		this.file = file;
		this.randomSeed = randomSeed;
		this.maxNodeNumber = maxNodeNumber;
		this.initialDataSize = initialDataSize;
		this.updateSize = updateSize;
		this.numberOfUpdates = numberOfUpdates;
		this.randomSize = false;
		this.statistics = new Statistics();
		this.updateDelay = updateDelay;

	}

	/**
	 * Size of updates varies randomly.
	 * 
	 * @param file          {@code String} name of file containing SWI-Prolog code
	 *                      to be executed
	 * @param randomSeed    {@code long} used to generate random updates
	 * @param maxNodeNumber {@code int} maximum number of nodes contained in
	 *                      randomly generated graph
	 * @param updateDelay   {@code int} waiting time in milliseconds between updates
	 *                      in stream
	 */
	public SyntheticUpdateStreamRun(String file, long randomSeed, int maxNodeNumber, int numberOfUpdates,
			int updateDelay) {
		this.file = file;
		this.randomSeed = randomSeed;
		this.maxNodeNumber = maxNodeNumber;
		this.numberOfUpdates = numberOfUpdates;
		this.randomSize = true;
		this.statistics = new Statistics();
		this.updateDelay = updateDelay;

	}

	/**
	 * Create a stream with {@code numberOfUpdates}-many updates that each randomly
	 * add (new) and delete (available) {@code updateSize}-many facts (i.e., edges)
	 * to a graph/dataset that starts with {@code initialDataSize}-many facts. A
	 * query asking for every fact is stated after each update.
	 * 
	 * 
	 * @param out           {@link PrintWriter} to write updates to stream
	 * @param maxNodeNumber {@code int} maximum number of nodes in created random
	 *                      graph of edges
	 * @param randomSeed    {@code long} seed used to randomly create updates
	 * @param printUpdates  {@code boolean} states if updates and their overlap with
	 *                      direct predecessor are printed to standard output
	 * @return a list of sets of facts representing the sequence of datasets created
	 *         by the update stream
	 */
	List<Set<Fact>> createUpdateStream(PrintWriter out, boolean printUpdates) {

		List<Set<Fact>> datasets = new LinkedList<>();

		GraphMaintainer gm = new GraphMaintainer(maxNodeNumber, randomSeed);

		// store previous update to compute overlap
		Update pre = new Update(new HashSet<>(), new HashSet<>());
		HashSet<Fact> replaced_del = new HashSet<>();
		HashSet<Fact> replaced_add = new HashSet<>();
		Update u;

		// create stream of random updates
		for (int i = 1; i <= numberOfUpdates; i++) {

			// create random update
			if (randomSize) {
				u = gm.createUpdateRandom();
			} else {
				// first update initializes dataset
				if (i == 1) {
					u = gm.createUpdate(initialDataSize, 0);
				} else {
					// update with fixed size
					u = gm.createUpdate(updateSize, updateSize);
				}
			}

			// store updated dataset
			datasets.add(gm.getCurrentDataset());

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
				String[] us = u.toString().split(":");
				System.out.println(i + ": " + us[0]);
				System.out.println("   " + us[1]);
				// print size of overlap with previous update
				System.out.println(" Overlap with previous: replaced del = " + replaced_del.size()
						+ " - replaced add = " + replaced_add.size());
			}

			// delay stream
			try {
				TimeUnit.MILLISECONDS.sleep(updateDelay);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}

			// write update to stream
			out.println(u.added.toString());
			out.println(u.deleted.toString());
			
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

}
