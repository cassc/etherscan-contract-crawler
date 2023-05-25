// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

abstract contract RewardDistributionRecipient is Context, AccessControl {
    bytes32 public constant DISTRIBUTION_ASSIGNER_ROLE = keccak256("DISTRIBUTION_ASSIGNER_ROLE");

    address public rewardDistribution;

    constructor(address assigner) {
        _setupRole(DISTRIBUTION_ASSIGNER_ROLE, assigner);
    }

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "RewardDisributionRecipient::onlyRewardDistribution: Caller is not RewardsDistribution contract"
        );
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ----- rewardDistribution ----- */

    function notifyRewardAmount(uint256 reward) external virtual;

    /* ----- DISTRIBUTION_ASSIGNER_ROLE ----- */

    function setRewardDistribution(address _rewardDistribution)
        external
    {
        require(
            hasRole(DISTRIBUTION_ASSIGNER_ROLE, _msgSender()),
            "RewardDistributionRecipient::setRewardDistribution: must have distribution assigner role"
        );
        rewardDistribution = _rewardDistribution;
    }
}