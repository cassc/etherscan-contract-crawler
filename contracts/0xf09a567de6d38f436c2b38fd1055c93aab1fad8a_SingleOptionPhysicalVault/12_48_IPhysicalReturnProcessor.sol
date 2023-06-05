// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Describes Option NFT
interface IPhysicalReturnProcessor {
    function returnOnExercise(address[] calldata _depositors) external;
}