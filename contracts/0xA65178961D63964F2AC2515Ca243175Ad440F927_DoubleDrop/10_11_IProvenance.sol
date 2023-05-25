// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IProvenance {
    function getRandomProvenance() external returns (uint256);

    error ProvenanceAlreadyRequested();
    error ProvenanceAlreadyGenerated();
    error ProvenanceNotGenerated();
}