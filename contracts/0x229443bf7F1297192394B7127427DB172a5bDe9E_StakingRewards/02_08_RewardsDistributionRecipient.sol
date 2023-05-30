// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/RewardsDistributionRecipient.sol
abstract contract RewardsDistributionRecipient is Owned {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}