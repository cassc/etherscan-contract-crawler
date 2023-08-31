// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Rewards Manager Derived State
 */
interface IRewardsManagerDerivedState {

    /**
     *  @notice Calculate the amount of rewards that have been accumulated by a staked `NFT`.
     *  @param  tokenId_      `ID` of the staked `LP` `NFT`.
     *  @param  epochToClaim_ The end burn epoch to calculate rewards for (rewards calculation starts from the last claimed epoch).
     *  @return The amount of rewards earned by the staked `NFT`.
     */
    function calculateRewards(
        uint256 tokenId_,
        uint256 epochToClaim_
    ) external view returns (uint256);

}