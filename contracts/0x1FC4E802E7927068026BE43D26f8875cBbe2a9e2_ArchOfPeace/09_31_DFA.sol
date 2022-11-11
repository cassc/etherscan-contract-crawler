// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Each possible state except default value (0x00) is a valid state
/// @dev Any valid state can only be reached if there is a transition allowing so
/// @dev DFA correctness and minimization has to be evaluated offchain
/// @dev DFA eventual runtime info must be kept into importing contract or offchain
library DFA {
    struct Dfa {
        bytes32 init;
        mapping(bytes32 => bool) accepting;
        mapping(bytes32 => mapping(bytes32 => bytes32)) transitions;
    }

    function addTransition(Dfa storage self, bytes32 from, bytes32 to, bytes32 symbol) internal {
        require(from != 0x00, "DFA: from invalid");
        require(to != 0x00, "DFA: to invalid");
        require(self.transitions[from][symbol] == 0x00, "DFA: existent transition");

        self.transitions[from][symbol] = to;
    }

    function removeTransition(Dfa storage self, bytes32 from, bytes32 symbol) internal {
        delete self.transitions[from][symbol];
    }

    function setInitial(Dfa storage self, bytes32 state) internal {
        self.init = state;
    }

    function addAccepting(Dfa storage self, bytes32 state) internal {
        self.accepting[state] = true;
    }

    function removeAccepting(Dfa storage self, bytes32 state) internal {
        delete self.accepting[state];
    }

    /// @dev Caller must handle non existing transition returning 0x00
    function transition(Dfa storage self, bytes32 from, bytes32 symbol) internal view returns (bytes32) {
        return self.transitions[from][symbol];
    }

    function isAccepting(Dfa storage self, bytes32 state) internal view returns (bool) {
        return self.accepting[state];
    }

    function initial(Dfa storage self) internal view returns (bytes32) {
        return self.init;
    }
}