package graph;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

public class Fact {

	String predicate;
	List<String> arguments;

	public Fact(String predicate, List<String> arguments) {
		this.predicate = predicate;
		this.arguments = arguments;
	}

	/**
	 * 
	 * @param bracket {@code String} that represents a fact in the form of
	 *                {@code [predicate, arg1, arg2, ...]}
	 * @throws Exception String has to be in bracket format
	 */
	public Fact(String bracket) throws Exception {
		if (bracket.startsWith("[") && bracket.endsWith("]")) {
			String[] parts = bracket.substring(1, bracket.length() - 1).split(",");
			this.predicate = parts[0];
			this.arguments = Arrays.asList(parts).subList(1, parts.length);
		} else
			throw new Exception("String has to be of form \"[ ... ]\"");

	}

	/**
	 * Transforms fact {@code f(a1,a2,...)} into a String {@code [f,a1,a2,...]}
	 */
	public String toString() {
		LinkedList<String> factList = new LinkedList<>(arguments);
		factList.addFirst(predicate);
		return factList.toString();
	}

	@Override
	public boolean equals(Object f) {
		return this.toString().equals(f.toString());

	}

	@Override
	public int hashCode() {
		return this.toString().hashCode();
	}

}