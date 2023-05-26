// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time

pragma solidity ^0.8.3;

// Inheritance
import "./StakingRewards.sol";

interface IWETH {
    function deposit() external payable;
}

interface IACAP {
    function claimReflection() external;
}


contract StakingRewardsWithReflection is StakingRewards {
    /* ========== CONSTRUCTOR ========== */

    IWETH public immutable weth;

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        IWETH _weth
    ) StakingRewards(_owner, _rewardsDistribution, _rewardsToken, _stakingToken) {
        weth = _weth;
    }

    /// @notice Claims reflection ETH for the staking contract
    function claimReflection() external onlyOwner {
        IACAP(address(stakingToken)).claimReflection();
    }

    /// @notice Converts ETH in contract into WETH
    function convertETH() external onlyOwner {
        weth.deposit{ value: address(this).balance }();
    }

    receive() external payable {}
}