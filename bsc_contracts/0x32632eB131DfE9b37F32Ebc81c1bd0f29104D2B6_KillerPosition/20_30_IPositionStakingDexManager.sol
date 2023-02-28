/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;


interface IPositionStakingDexManager {
    function stakeAfterMigrate(uint256 nftId, address user ) external;
}