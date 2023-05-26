// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ICandidateFactory {
    function deploy(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _name,
        address _committee,
        address _seigManager
    )
        external
        returns (address);
}