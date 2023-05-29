// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface ILandMintUpdater {

    function updateLandMintingTime(uint256 _id) external;

}

interface ITierTwoMintUpdater {

    function updateTierTwoMintingTime(uint256 _id) external;

}