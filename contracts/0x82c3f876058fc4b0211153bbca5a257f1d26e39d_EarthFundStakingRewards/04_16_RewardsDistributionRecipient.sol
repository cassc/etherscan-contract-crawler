// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

abstract contract RewardsDistributionRecipient is Owned {
    address public rewardDistributor;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardDistributor, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardDistributor) external onlyOwner {
        rewardDistributor = _rewardDistributor;
    }
}