// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/rewardsProxy/IRewardsProxy.sol";

import "./interfaces/oracle/IOracleRegistry.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Factory contract for Silica Account
 * @author Alkimiya Team
 */
contract RewardsProxy is IRewardsProxy {
    IOracleRegistry immutable oracleRegistry;

    constructor(address _oracleRegistry) {
        require(_oracleRegistry != address(0), "OracleRegistry address cannot be zero");
        oracleRegistry = IOracleRegistry(_oracleRegistry);
    }

    ///  @notice Function to stream rewards to Silica contracts
    function streamRewards(StreamRequest[] calldata streamRequests) external override {
        uint256 numRequest = streamRequests.length;
        for (uint256 i = 0; i < numRequest; ++i) {
            streamReward(streamRequests[i]);
        }
        emit RewardsStreamed(streamRequests);
    }

    /// @notice Internal function to safely stream rewards to silica contracts
    function streamReward(StreamRequest memory streamRequest) internal {
        SafeERC20.safeTransferFrom(IERC20(streamRequest.rToken), msg.sender, streamRequest.silicaAddress, streamRequest.amount);
    }
}