// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../curve/2Pool/Curve2PlainPool.sol";
import "../ConvexBase.sol";

/// @title This strategy will deposit collateral token in a Curve 2Pool and stake lp token to convex.
contract Convex2PlainPool is Curve2PlainPool, ConvexBase {
    using SafeERC20 for IERC20;

    constructor(
        address pool_,
        address crvPool_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        uint256 collateralIdx_,
        uint256 convexPoolId_,
        string memory _name
    )
        Curve2PlainPool(pool_, crvPool_, crvSlippage_, masterOracle_, swapper_, collateralIdx_, _name)
        ConvexBase(convexPoolId_)
    {
        (address _lp, , , , , ) = BOOSTER.poolInfo(convexPoolId_);
        require(_lp == address(crvLp), "incorrect-lp-token");
    }

    function lpBalanceStaked() public view override returns (uint256 _total) {
        _total = cvxCrvRewards.balanceOf(address(this));
    }

    function _approveToken(uint256 amount_) internal virtual override {
        crvLp.safeApprove(address(BOOSTER), amount_);
        super._approveToken(amount_);
    }

    function _claimRewards() internal override {
        require(cvxCrvRewards.getReward(address(this), true), "reward-claim-failed");
    }

    function _stakeAllLp() internal override {
        uint256 _balance = crvLp.balanceOf(address(this));
        if (_balance > 0) {
            require(BOOSTER.deposit(convexPoolId, _balance, true), "booster-deposit-failed");
        }
    }

    /**
     * @notice Unstake all LPs
     * @dev This function is called by `_beforeMigration()` hook
     * Should claim rewards that will be swept later
     */
    function _unstakeAllLp() internal override {
        cvxCrvRewards.withdrawAllAndUnwrap(true);
    }

    /**
     * @notice Unstake LPs
     * Don't claiming rewards because `_claimRewards()` already does that
     */
    function _unstakeLp(uint256 amount_) internal override {
        if (amount_ > 0) {
            require(cvxCrvRewards.withdrawAndUnwrap(amount_, false), "withdraw-and-unwrap-failed");
        }
    }

    /// @dev convex pool can add new rewards. This method refresh list.
    function setRewardTokens(
        address[] memory /*_rewardTokens*/
    ) external override onlyKeeper {
        // Claims all rewards, if any, before updating the reward list
        _claimRewardsAndConvertTo(address(collateralToken));
        rewardTokens = _getRewardTokens();
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }
}