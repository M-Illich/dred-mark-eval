package data;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

public class Fact {

	public String predicate;
	public List<String> arguments;

	public Fact(String predicate, List<String> arguments) {
		this.predicate = predicate;
		this.arguments = arguments;
	}

	/**
	 * 
	 * @param string {@code String} that represents a fact in the form of
	 *               {@code [predicate, arg1, arg2, ...]} or
	 *               {@code predicate(arg1, arg2, ...)}
	 * 
	 */
	public Fact(String string) {
		// [predicate, arg1, arg2, ...]
		if (string.startsWith("[") && string.endsWith("]")) {
			String[] parts = string.substring(1, string.length() - 1).split(",");
			for(int i = 0; i < parts.length; i++) {
				parts[i] = parts[i].trim();
			}
			this.predicate = parts[0];
			this.arguments = Arrays.asList(parts).subList(1, parts.length);
		}
		// predicate(arg1, arg2, ...)
		else {
			this.predicate = string.substring(0, string.indexOf("("));
			String[] parts = string.substring(string.indexOf("(") + 1, string.length() - 1).split(",");
			for(int i = 0; i < parts.length; i++) {
				parts[i] = parts[i].trim();
			}
			this.arguments = Arrays.asList(parts).subList(0, parts.length);
		}

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