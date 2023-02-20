// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract WordPuzzle is Ownable {
    bytes32 private _solutionHash;
    uint256 private _numWords;

    constructor() {}

    function setSolutionHash(bytes32 _newSolutionHash, uint256 _newNumWords) public onlyOwner {
        _solutionHash = _newSolutionHash;
        _numWords = _newNumWords;
    }

    function checkSolution(string[] calldata solution) public view returns (bool) {
        uint256 solLen = solution.length;

        require(solLen > 0, "l0");

        if (solLen != _numWords) {
            return false;
        }

        bytes32 providedSolution = keccak256(abi.encodePacked(solution[0]));
        for (uint256 i = 1; i < solLen; i++) {
            providedSolution = keccak256(abi.encodePacked(providedSolution, solution[i]));
        }

        return (providedSolution == _solutionHash);
    }

    function getSolution(string[] calldata solution) public pure returns (bytes32) {
        uint256 solLen = solution.length;

        require(solLen > 0, "l0");

        bytes32 providedSolution = keccak256(abi.encodePacked(solution[0]));
        for (uint256 i = 1; i < solLen; i++) {
            providedSolution = keccak256(abi.encodePacked(providedSolution, solution[i]));
        }

        return providedSolution;
    }

    receive() external payable {
        require(false, "This address should not be receiving funds by fallback!");
    }
}

////////////////////////////////////////