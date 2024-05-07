package jni;

import de.learnlib.algorithm.LearningAlgorithm.MealyLearner;
import de.learnlib.algorithm.lstar.mealy.ExtensibleLStarMealyBuilder;
import de.learnlib.driver.ContextExecutableInputSUL;
import de.learnlib.filter.cache.sul.SULCaches;
import de.learnlib.filter.statistic.sul.ResetCounterSUL;
import de.learnlib.oracle.EquivalenceOracle.MealyEquivalenceOracle;
import de.learnlib.oracle.equivalence.mealy.RandomWalkEQOracle;
import de.learnlib.oracle.membership.SULOracle;
import de.learnlib.statistic.StatisticSUL;
import de.learnlib.sul.ContextExecutableInput;
import de.learnlib.sul.ContextHandler;
import de.learnlib.sul.SUL;
import de.learnlib.util.Experiment.MealyExperiment;
import de.learnlib.util.statistic.SimpleProfiler;
import net.automatalib.alphabet.Alphabet;
import net.automatalib.alphabet.Alphabets;
import net.automatalib.automaton.transducer.MealyMachine;
import net.automatalib.serialization.dot.GraphDOT;
import net.automatalib.visualization.Visualization;
import net.automatalib.word.Word;

import java.util.*;

public class Runner {

    private static final double RESET_PROBABILITY = 0.05;
    private static final int MAX_STEPS = 10_000;
    private static final int RANDOM_SEED = 46_346_293;

    public static void main(String[] args) throws Exception {
        LexerDriver driver = new LexerDriver();


        // not yet
        for (char c = 32; c <= 126; c++) {
            driver.addSymbol(c);
        }
//        driver.addSymbol('\n');

        //works

//        driver.addSymbol('a');
//        driver.addSymbol(' ');
//        driver.addSymbol('1');
//        driver.addSymbol('\n');
//        driver.addSymbol('\"');
//driver.addSymbol('/');
//driver.addSymbol('*');

//        driver.addSymbol((char) -1);// EOF

//        // add token dictionary
        LexerInput.tokenDict.put(1, "NO TOKEN");
        LexerInput.tokenDict.put(2, "NUMBER");
        LexerInput.tokenDict.put(3, "WHITESPACE");
        LexerInput.tokenDict.put(4, "IDENT");
        LexerInput.tokenDict.put(5, "STRING");
        LexerInput.tokenDict.put(6, "COMMENT");
        LexerInput.tokenDict.put(99, "UNKNOWN");

//        // add token dictionary
//        LexerInput.tokenDict.put(2, "COMMENT");
//        LexerInput.tokenDict.put(1, "CODE");

        // oracle for counting queries wraps sul
        StatisticSUL<LexerInput, String> statisticSul =
                new ResetCounterSUL<>("membership queries", driver);

        SUL<LexerInput, String> effectiveSul = statisticSul;
        // use caching in order to avoid duplicate queries
        effectiveSul = SULCaches.createCache(driver.getAlphabet(), effectiveSul);

        SULOracle<LexerInput, String> mqOracle = new SULOracle<>(effectiveSul);

        // create initial set of suffixes
        List<Word<LexerInput>> suffixes = new ArrayList<>();
        driver.symbols.forEach(s -> suffixes.add(Word.fromSymbols(s)));

        // construct L* instance (almost classic Mealy version)
        // almost: we use words (Word<String>) in cells of the table
        // instead of single outputs.
        MealyLearner<LexerInput, String> lstar =
                new ExtensibleLStarMealyBuilder<LexerInput, String>().withAlphabet(driver.getAlphabet()) // input alphabet
                        .withOracle(mqOracle) // membership oracle
                        .withInitialSuffixes(suffixes) // initial suffixes
                        .create();

        // create random walks equivalence test
        MealyEquivalenceOracle<LexerInput, String> randomWalks =
                new RandomWalkEQOracle<>(driver, // system under learning
                        RESET_PROBABILITY, // reset SUL w/ this probability before a step
                        MAX_STEPS, // max steps (overall)
                        false, // reset step count after counterexample
                        new Random(RANDOM_SEED) // make results reproducible
                );

        // construct a learning experiment from
        // the learning algorithm and the random walks test.
        // The experiment will execute the main loop of
        // active learning
        MealyExperiment<LexerInput, String> experiment =
                new MealyExperiment<>(lstar, randomWalks, driver.getAlphabet());

        // turn on time profiling
        experiment.setProfile(true);

        // enable logging of models
        experiment.setLogModels(true);

        // run experiment
        experiment.run();

        // get learned model
        MealyMachine<?, LexerInput, ?, String> result = experiment.getFinalHypothesis();

        // report results
        System.out.println("-------------------------------------------------------");

        // profiling
        SimpleProfiler.logResults();

        // learning statistics
        System.out.println(experiment.getRounds().getSummary());
        System.out.println(statisticSul.getStatisticalData().getSummary());

        // model statistics
        System.out.println("States: " + result.size());
        System.out.println("Sigma: " + driver.getAlphabet().size());

        // show model
        System.out.println();
        System.out.println("Model: ");

        GraphDOT.write(result, driver.getAlphabet(), System.out); // may throw IOException!
        Visualization.visualize(result, driver.getAlphabet());

        System.out.println("-------------------------------------------------------");

    }

    static class LexerDriver extends ContextExecutableInputSUL<LexerInput, String, Lexer> {
        private final List<LexerInput> symbols = new ArrayList<>();

        public LexerDriver() {
            super(new LexerContextHandler());
        }

        public Alphabet<LexerInput> getAlphabet() {
            return Alphabets.fromList(symbols);
        }

        public LexerInput addSymbol(Character symbol) {
            LexerInput input = new LexerInput(symbol);
            symbols.add(input);
            return input;
        }
    }

    static class LexerInput implements ContextExecutableInput<String, Lexer> {
        public static Map<Integer, String> tokenDict = new HashMap<Integer, String>();

        private final Character symbol;

        public LexerInput(Character symbol) {
            this.symbol = symbol;
        }

        @Override
        public String execute(Lexer lexer) {
            // print the thread
            System.out.println("[" + Thread.currentThread().getId() + "] LEX: " + symbol + " (" + (int) symbol + ")");
            Tokens token = lexer.lex(symbol);
            System.out.println("[" + Thread.currentThread().getId() + "] TOKEN: " + token);
            return token.toStringWithDict(tokenDict);
        }

        @Override
        public String toString() {
            return String.valueOf(symbol);
        }
    }

    static class LexerContextHandler implements ContextHandler<Lexer> {
        @Override
        public Lexer createContext() {
            return Lexer.create();
        }

        @Override
        public void disposeContext(Lexer lexer) {
            lexer.close();
        }
    }
}