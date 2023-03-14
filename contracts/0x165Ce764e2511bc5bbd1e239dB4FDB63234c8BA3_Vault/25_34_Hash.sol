// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @notice Library to provide utils for hashing and hash compatison of Spool related data
 */
library Hash {
    function hashReallocationTable(uint256[][] memory reallocationTable) internal pure returns(bytes32) {
        return keccak256(abi.encode(reallocationTable));
    }

    function hashStrategies(address[] memory strategies) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(strategies));
    }

    function sameStrategies(address[] memory strategies1, address[] memory strategies2) internal pure returns(bool) {
        return hashStrategies(strategies1) == hashStrategies(strategies2);
    }

    function sameStrategies(address[] memory strategies, bytes32 strategiesHash) internal pure returns(bool) {
        return hashStrategies(strategies) == strategiesHash;
    }
}