package stream;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import graph.Fact;
import graph.GraphMaintainer;
import graph.Update;

public class UpdateStreamRun extends StreamToProlog {

	/**
	 * name of file containing SWI-Prolog code to be executed
	 */
	String file;

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
	 * list of answer sets for each stated query
	 */
	public List<Set<Fact>> queryAnswers;

	/**
	 * list of datasets created by sequence of updates
	 */
	public List<Set<Fact>> datasets;

	/**
	 * information about number of applied rules, marked facts, and runtime
	 */
	public Statistics statistics;

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
	public UpdateStreamRun(String file, long randomSeed, int maxNodeNumber, int initialDataSize, int updateSize,
			int numberOfUpdates, int updateDelay) {
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
	public UpdateStreamRun(String file, long randomSeed, int maxNodeNumber, int numberOfUpdates, int updateDelay) {
		this.file = file;
		this.randomSeed = randomSeed;
		this.maxNodeNumber = maxNodeNumber;
		this.numberOfUpdates = numberOfUpdates;
		this.randomSize = true;
		this.statistics = new Statistics();
		this.updateDelay = updateDelay;

	}

	/**
	 * Process a stream of updates that adapt a graph by adding and deleting edges.
	 * The updates are created randomly based on the caller's attributes. The Prolog
	 * code in {@code file} incrementally maintains the materialization of the graph
	 * by computing the transitive closure of paths comprising connected edges.
	 * 
	 * @param printUpdates         {@code boolean} states if updates and their
	 *                             overlap with direct predecessor are printed to
	 *                             standard output
	 * 
	 * @param printMaterialization {@code boolean} states if materialization
	 *                             obtained after each update is printed to standard
	 *                             output
	 * 
	 * @param printStatistics      {@code boolean} states if number of applied rules
	 *                             and runtime is printed to standard output
	 * 
	 */
	public void execute(boolean printUpdates, boolean printMaterialization, boolean printStatistics) {

		try {
			// open server
			ServerSocket serverSocket = new ServerSocket(0);

			// execute prolog file
			Process prologCall = callProlog(serverSocket.getLocalPort(), file);

			// accept connection from prolog file
			Socket clientSocket = serverSocket.accept();

			PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true);
			BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

			// create stream of random updates each followed by a query
			datasets = createUpdateStream(out, printUpdates);

			// read answers for each query
			queryAnswers = readAnswers(in, printMaterialization);

			in.close();
			out.close();
			clientSocket.close();
			serverSocket.close();

			// read output from executed commands
			BufferedReader cmdReader = new BufferedReader(new InputStreamReader(prologCall.getInputStream()));
			if (printStatistics) {
				System.out.println("-- command output --");
			}
			statistics.integrateData(readOutput(cmdReader, printStatistics));
			cmdReader.close();
			// get additional messages, like execution time if available
			BufferedReader cmdError = new BufferedReader(new InputStreamReader(prologCall.getErrorStream()));
			statistics.integrateData(readOutput(cmdError, printStatistics));
			cmdError.close();

		} catch (IOException e) {
			e.printStackTrace();
		}

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
	private List<Set<Fact>> createUpdateStream(PrintWriter out, boolean printUpdates) {

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
					// initialize dataset with complete materialization
//					SimpleMaterialization sm = new SimpleMaterialization(gm.createUpdate(initialDataSize, 0).add);
//					u = new Update(sm.execute(), Set.of());
					u = gm.createUpdate(initialDataSize, 0); // TODO
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
				for (Fact fact : u.add) {
					if (pre.delete.contains(fact)) {
						replaced_del.add(fact);
					}
				}
				for (Fact fact : u.delete) {
					if (pre.add.contains(fact)) {
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
			out.println(u.toString());

			// insert query directly after each update (asking for every fact)
			out.println("X:");
			if (printUpdates) {
				System.out.println("query " + i);
			} else {
				if (i == 1) {
					System.out.print("query");
				}
				System.out.print(" " + i);
			}

			// TODO test
//			if (i == 1) {
//				try {
//					TimeUnit.MILLISECONDS.sleep(5000);
//				} catch (InterruptedException e) {
//					e.printStackTrace();
//				}
//			}

		}

		/* test example */
//		out.println("[[edge,1,2], [edge,2,3], [edge,3,4], [edge,3,5]]:[]");
//		out.println("X:");	// query	
//		try {
//			TimeUnit.MILLISECONDS.sleep(1000);
//		} catch (Exception e) {
//			e.printStackTrace();
//		}
//		out.println("[]:[[edge,2,3], [edge,3,4], [edge,3,5]]");
//		out.println("X:");	// query
//		out.println("[[edge,2,3], [edge,3,4], [edge,3,5]]:[]");
//		out.println("X:");	// query

		// indicate end of stream
		out.println("[]:[]");
		System.out.println("");

		return datasets;

	}

}
