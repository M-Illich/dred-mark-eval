package stream;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;
import java.util.Set;

import data.Fact;

public abstract class UpdateStreamRun extends StreamToProlog {

	/**
	 * name of file containing SWI-Prolog code to be executed
	 */
	String file;

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
	 * Process a stream of updates that adapt a graph by adding and deleting edges.
	 * The updates are created randomly based on the caller's attributes. The Prolog
	 * code in {@code file} incrementally maintains the materialization of the
	 * graph.
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
	abstract List<Set<Fact>> createUpdateStream(PrintWriter out, boolean printUpdates);

}