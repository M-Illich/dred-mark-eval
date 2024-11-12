package data;

import static org.junit.Assert.assertEquals;

import java.util.List;

import org.junit.Test;

public class FactTest {

	@Test
	public void testConstructor() {
//		Fact fact =  new Fact("p", List.of("1","2"));
		Fact bracket = new Fact("[p, 1, 2]");
		Fact atom = new Fact("p(1, 2)");	
		
		System.out.println(atom.predicate);
		for (String s : atom.arguments) {
			System.out.println(s);
		}

		assertEquals("p", bracket.predicate);
		assertEquals("1", bracket.arguments.get(0));
		assertEquals("2", bracket.arguments.get(1));
		assertEquals(2, bracket.arguments.size());

		assertEquals("p", atom.predicate);
		assertEquals("1", atom.arguments.get(0));
		assertEquals("2", atom.arguments.get(1));
		assertEquals(2, atom.arguments.size());
	}

}
