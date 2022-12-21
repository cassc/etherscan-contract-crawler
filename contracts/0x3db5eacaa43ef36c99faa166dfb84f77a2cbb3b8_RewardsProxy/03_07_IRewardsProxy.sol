// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Alkimiya Reward Proxy interface
 * @author Alkimiya Team
 * */
interface IRewardsProxy {
    event RewardsStreamed(StreamRequest[] streamRequests);

    struct StreamRequest {
        address silicaAddress;
        address rToken;
        uint256 amount;
    }

    struct RewardDue {
        address silicaAddress;
        address rToken;
        uint256 amount;
    }

    /// @notice Function to stream rewards to Silica contracts
    function streamRewards(StreamRequest[] calldata streamRequests) external;
}