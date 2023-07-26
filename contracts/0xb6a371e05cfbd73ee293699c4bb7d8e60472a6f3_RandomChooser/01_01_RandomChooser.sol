// SPDX-License-Identifier: MIT

/**
 ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████──────────██████─██████████████─██████████████─██████──████████─██████████████─██████████████────
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██████████──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██────
─██░░██████░░██─██░░██████░░██─██░░░░░░░░░░██──██░░██─██░░██████████─██░░██████░░██─██░░██──██░░████─██░░██████████─██░░██████████────
─██░░██──██░░██─██░░██──██░░██─██░░██████░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██──██░░██───██░░██─────────██░░██────────────
─██░░██████░░██─██░░██████░░██─██░░██──██░░██──██░░██─██░░██─────────██░░██████░░██─██░░██████░░██───██░░██████████─██░░██████████────
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██──██░░██─██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██────
─██░░██████████─██░░██████░░██─██░░██──██░░██──██░░██─██░░██─────────██░░██████░░██─██░░██████░░██───██░░██████████─██████████░░██────
─██░░██─────────██░░██──██░░██─██░░██──██░░██████░░██─██░░██─────────██░░██──██░░██─██░░██──██░░██───██░░██─────────────────██░░██────
─██░░██─────────██░░██──██░░██─██░░██──██░░░░░░░░░░██─██░░██████████─██░░██──██░░██─██░░██──██░░████─██░░██████████─██████████░░██────
─██░░██─────────██░░██──██░░██─██░░██──██████████░░██─██░░░░░░░░░░██─██░░██──██░░██─██░░██──██░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██────
─██████─────────██████──██████─██████──────────██████─██████████████─██████──██████─██████──████████─██████████████─██████████████────
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 * @dev @henry
 */

pragma solidity 0.8.20;

/// @title A random number chooser contradct
/// @author henry // gitpancake
/// @notice You can use this contract to randomise numbers and store them on chain
/// @dev this does not utilise VRF, this contract is a naive implementation of randomisation
contract RandomChooser {
  	mapping(string => uint[]) results;

    event RandomComplete(address user, uint[] result);
	
	/// @notice Randomise a sequence of numbers, producing an array of length resultLimit, and store the result with the given key
    /// @dev Uses the Fisher-Yates shuffle algorithm (thanks @brougkr)
    /// @param key The key to store the result under
    /// @param resultLimit the total number of results to produce
	/// @param array the array of numbers to randomise
    function randomiseSequence(string calldata key, uint resultLimit, uint[] memory array) public {
		require(array.length >= resultLimit, "Array length must be at least resultLimit.");
		require(results[key].length == 0, "Results for key already exists.");

        for(uint i = array.length; i > 1; i--) 
        {
            uint j = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % i;
            (array[i - 1], array[j]) = (array[j], array[i - 1]);
        }

        uint[] memory result = new uint[](resultLimit);

        for(uint i = 0; i < resultLimit; i++) {
            result[i] = array[i];
        }

		results[key] = result;

		emit RandomComplete(msg.sender, result);
    }

	/// @notice View the randomised results for a given key
    /// @param key The key to view the results for
	function viewResults(string calldata key) public view returns (uint[] memory) {
		return results[key];
	}
}