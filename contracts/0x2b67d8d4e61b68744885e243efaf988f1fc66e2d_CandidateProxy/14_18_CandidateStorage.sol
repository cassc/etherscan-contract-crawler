// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract CandidateStorage   {
    mapping(bytes4 => bool) internal _supportedInterfaces;
    bool public isLayer2Candidate;
    address public candidate;
    string public memo;

    address public committee;
    address public seigManager;

}