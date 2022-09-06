// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IProofOfHumanityProxy {
    function isRegistered(address _submissionID) external view returns (bool);
}