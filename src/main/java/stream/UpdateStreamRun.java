package stream;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashSet;

import graph.Fact;
import graph.GraphMaintainer;
import graph.Update;

public class UpdateStreamRun {

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
	
	
	/*
	 *  --- TODO ---
	 * if asked, store answers, statistics etc. for later comparison (?)
	 * 
	 */

	/**
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
	 */
	public UpdateStreamRun(String file, long randomSeed, int maxNodeNumber, int initialDataSize, int updateSize,
			int numberOfUpdates) {
		this.file = file;
		this.randomSeed = randomSeed;
		this.maxNodeNumber = maxNodeNumber;
		this.initialDataSize = initialDataSize;
		this.updateSize = updateSize;
		this.numberOfUpdates = numberOfUpdates;

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
			createUpdateStream(out, printUpdates);

			// test examples
//			out.println("[[edge,1,2], [edge,2,3], [edge,3,4]]:[]");
//			out.println("[]:[[edge,3,4]]");
//			out.println("X:"); // query
//			out.println("[[edge,2,5],[edge,5,3]]:[]");
//			out.println("X:"); // query
//			out.println("[]:[[edge,2,3]]");
//			out.println("X:"); // query

			// read answers for each query
			if (printMaterialization) {
				readOutput(in);
				System.out.println("");
			}

			in.close();
			out.close();
			clientSocket.close();
			serverSocket.close();

			// read output from executed commands
			if (printStatistics) {
				BufferedReader cmdReader = new BufferedReader(new InputStreamReader(prologCall.getInputStream()));
				System.out.println("-- command output --");
				readOutput(cmdReader);
				cmdReader.close();
				// get additional messages, like execution time if available
				BufferedReader cmdError = new BufferedReader(new InputStreamReader(prologCall.getErrorStream()));
				readOutput(cmdError);
				cmdError.close();
			}

		} catch (IOException e) {
			e.printStackTrace();
		}

	}

	/**
	 * Create a stream with {@code numberOfUpdates}-many updates that each randomly
	 * add (new) and delete (available) {@code updateSize}-many facts (i.e., edges)
	 * to a graph that starts with {@code initialDataSize}-many facts. A query
	 * asking for every fact is stated after each update.
	 * 
	 * 
	 * @param out           {@link PrintWriter} to write updates to stream
	 * @param maxNodeNumber {@code int} maximum number of nodes in created random
	 *                      graph of edges
	 * @param randomSeed    {@code long} seed used to randomly create updates
	 * @param printUpdates  {@code boolean} states if updates and their overlap with
	 *                      direct predecessor are printed to standard output
	 */
	private void createUpdateStream(PrintWriter out, boolean printUpdates) {

		GraphMaintainer gm = new GraphMaintainer(maxNodeNumber, randomSeed);

		// store previous update to compute overlap
		Update pre = new Update(new HashSet<>(), new HashSet<>());
		HashSet<Fact> replaced_del = new HashSet<>();
		HashSet<Fact> replaced_add = new HashSet<>();

		// create stream of random updates
		for (int i = 1; i <= numberOfUpdates; i++) {

			// create random update
			Update u = gm.createUpdate(updateSize, updateSize);
			// first update initializes dataset
			if (i == 1) {
				u = gm.createUpdate(initialDataSize, 0);
			}

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
				String[] us = u.toString().split(":");
				System.out.println(i + ": " + us[0]);
				System.out.println("   " + us[1]);
				// print size of overlap with previous update
				System.out.println(" Overlap with previous: replaced del = " + replaced_del.size()
						+ " - replaced add = " + replaced_add.size());
			}

			// write update to stream
			out.println(u.toString());

			// insert query directly after each update (asking for every fact)
			out.println("X:");
			System.out.println("query " + i);

		}

		// indicate end of stream
		out.println("[]:[]");
		System.out.println("");

	}

	/**
	 * Read lines from provided input stream until {@code null} occurs
	 * 
	 * @param in {@link BufferedReader} for input stream
	 */
	private void readOutput(BufferedReader in) {
		String line;
		try {
			while ((line = in.readLine()) != null) {
				System.out.println(line);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Use command shell to execute the specified SWI-Prolog file, which
	 * communicates over the provided local port
	 * 
	 * @param localPort {@code int} local port used by server for update stream
	 * @param file      {@code String} name of SWI-Prolog file stored in
	 *                  {@code src/main/resources}
	 * @return {@link Process} object for executed command
	 */
	private Process callProlog(int localPort, String file) {

		ProcessBuilder pb = new ProcessBuilder();

		// prolog goal to initialize process, connect to specified local port, and
		// measure runtime
		String goal = "time(init(localhost:" + localPort + "))";

		// open command shell and call SWI-Prolog for specified file and goal
		pb.command("cmd.exe", "/c", "cd src/main/resources && swipl -g " + goal + " -t halt " + file);

		Process process = null;
		try {
			process = pb.start();
		} catch (IOException e) {
			e.printStackTrace();
		}

		return process;

	}

}
