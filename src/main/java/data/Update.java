package data;

import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.util.Set;

public class Update {

	public Set<Fact> added;
	public Set<Fact> deleted;

	public Update(Set<Fact> add, Set<Fact> delete) {
		this.added = add;
		this.deleted = delete;
	}

	/**
	 * Transform an update {@code ([F1(a1,a2), F2(a3), ...],[F3(a4,...),...])} into
	 * a String {@code [[F1,a1,a2],[F2,a3],...]:[[F3,a4,...],...]}
	 */
	public String toString() {
		return added.toString() + ":" + deleted.toString();
	}

	/**
	 * Write the update to the file called {@code name}. Each added or deleted fact
	 * F is written as {@code add(F).} or {@code delete(F).} in a line in the file.
	 * 
	 * @param name {@code String} name of file
	 */
	public void writeToFile(String name) {
		try {
			PrintWriter writer = new PrintWriter(name);

			for (Fact fact : added) {
				String args = fact.arguments.toString();
				args = args.substring(1, args.length() - 1);
				String line = "add(" + fact.predicate + "(" + args + ")).";
				writer.println(line);
			}
			for (Fact fact : deleted) {
				String args = fact.arguments.toString();
				args = args.substring(1, args.length() - 1);
				String line = "delete(" + fact.predicate + "(" + args + ")).";
				writer.println(line);
			}

			writer.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}

}
