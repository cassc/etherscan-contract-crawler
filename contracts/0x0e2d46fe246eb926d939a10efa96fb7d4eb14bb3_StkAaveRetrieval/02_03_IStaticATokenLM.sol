// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// relevant functions from https://etherscan.io/address/0x1dc16f168b0a2bb3fbda0fe1a1787f8b22c0aed8#code

interface IStaticATokenLM {
    /**
     * @notice Claim rewards on behalf of a user and send them to a receiver
     * @dev Only callable by if sender is onBehalfOf or sender is approved claimer
     * @param onBehalfOf The address to claim on behalf of
     * @param receiver The address to receive the rewards
     * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
     */
    function claimRewardsOnBehalf(
        address onBehalfOf,
        address receiver,
        bool forceUpdate
    ) external;

    /**
     * @notice The unclaimed rewards for a user in WAD
     * @param user The address of the user
     * @return The unclaimed amount of rewards in WAD
     */
    function getUnclaimedRewards(address user) external view returns (uint256);
}