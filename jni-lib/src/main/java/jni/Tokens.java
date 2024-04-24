package jni;

import java.util.Map;

public record Tokens(int first, int second) {
    @Override
    public String toString() {
        return "(" + first + ", " + second + ")";
    }

    public String toStringWithDict(Map<Integer, String> dict) {
        return dict.getOrDefault(first, String.valueOf(first)) + " | " + dict.getOrDefault(second, String.valueOf(second));
    }
}
