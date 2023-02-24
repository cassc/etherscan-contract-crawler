// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../ConvexTokenStaker.sol";
import { IConvexBaseRewardPool } from "../../../../interfaces/external/convex/IBaseRewardPool.sol";

/// @title ConvexTokenStakerMainnet
/// @author Angle Labs, Inc.
/// @dev Constants for borrow staker adapted to Curve LP tokens deposited on Convex Mainnet
abstract contract ConvexTokenStakerMainnet is ConvexTokenStaker {
    /// @inheritdoc BorrowStaker
    function claimableRewards(address from, IERC20 _rewardToken) external view override returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 newIntegral = _totalSupply != 0
            ? integral[_rewardToken] + (_rewardsToBeClaimed(_rewardToken) * BASE_36) / _totalSupply
            : integral[_rewardToken];
        uint256 newClaimable = (totalBalanceOf(from) * (newIntegral - integralOf[_rewardToken][from])) / BASE_36;
        return pendingRewardsOf[_rewardToken][from] + newClaimable;
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @inheritdoc ERC20Upgradeable
    function _afterTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal override {
        // Stake on Convex if it is a deposit
        if (from == address(0)) {
            // Deposit the Curve LP tokens into the convex contract and stake
            _changeAllowance(asset(), address(_convexBooster()), amount);
            _convexBooster().deposit(poolPid(), amount, true);
        }
    }

    /// @inheritdoc BorrowStaker
    function _withdrawFromProtocol(uint256 amount) internal override {
        baseRewardPool().withdrawAndUnwrap(amount, false);
    }

    /// @inheritdoc BorrowStaker
    /// @dev Should be overriden by implementation if there are more rewards
    function _claimGauges() internal override {
        // Claim on Convex
        address[] memory rewardContracts = new address[](1);
        rewardContracts[0] = address(baseRewardPool());
        _convexClaimZap().claimRewards(
            rewardContracts,
            new address[](0),
            new address[](0),
            new address[](0),
            0,
            0,
            0,
            0,
            0
        );
    }

    /// @inheritdoc BorrowStaker
    function _rewardsToBeClaimed(IERC20 rewardToken) internal view override returns (uint256 amount) {
        amount = baseRewardPool().earned(address(this));
        if (rewardToken == IERC20(address(_cvx()))) {
            // Computation made in the Convex token when claiming rewards check
            // https://etherscan.io/address/0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b#code
            uint256 totalSupply = _cvx().totalSupply();
            uint256 cliff = totalSupply / _cvx().reductionPerCliff();
            uint256 totalCliffs = _cvx().totalCliffs();
            if (cliff < totalCliffs) {
                uint256 reduction = totalCliffs - cliff;
                amount = (amount * reduction) / totalCliffs;

                uint256 amtTillMax = _cvx().maxSupply() - totalSupply;
                if (amount > amtTillMax) {
                    amount = amtTillMax;
                }
            }
        }
    }

    /// @inheritdoc ConvexTokenStaker
    function _crv() internal pure override returns (IERC20) {
        return IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    }

    // ========================== CONVEX-RELATED CONSTANTS =========================

    /// @inheritdoc ConvexTokenStaker
    function _convexBooster() internal pure override returns (IConvexBooster) {
        return IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    }

    /// @notice Address of the Convex contract that routes claim rewards
    function _convexClaimZap() internal pure returns (IConvexClaimZap) {
        return IConvexClaimZap(0xDd49A93FDcae579AE50B4b9923325e9e335ec82B);
    }

    /// @inheritdoc ConvexTokenStaker
    function _cvx() internal pure override returns (IConvexToken) {
        return IConvexToken(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Address of the Convex contract on which to claim rewards
    function baseRewardPool() public pure virtual returns (IConvexBaseRewardPool);
}