//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILandAuction {
    function winningsBidsOf(address user) external view returns (uint256);
}