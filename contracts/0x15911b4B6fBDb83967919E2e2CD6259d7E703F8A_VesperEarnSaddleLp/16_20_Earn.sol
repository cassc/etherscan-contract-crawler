// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "vesper-pools/contracts/interfaces/vesper/IEarnDrip.sol";
import "vesper-pools/contracts/interfaces/vesper/IVesperPool.sol";
import "./Strategy.sol";

abstract contract Earn is Strategy {
    using SafeERC20 for IERC20;

    address public immutable dripToken;

    uint256 public dripPeriod = 48 hours;
    uint256 public totalEarned; // accounting total coin earned after fee. This amount is not reported to pool.

    event DripPeriodUpdated(uint256 oldDripPeriod, uint256 newDripPeriod);

    constructor(address dripToken_) {
        require(dripToken_ != address(0), "dripToken-zero");
        dripToken = dripToken_;
    }

    /// @dev Converts excess collateral earned to drip token
    function _convertCollateralToDrip(uint256 _collateralAmount) internal virtual returns (uint256 _amountOut) {
        if (_collateralAmount > 0) {
            _amountOut = _swapExactInput(address(collateralToken), dripToken, _collateralAmount);
        }
    }

    /// @dev Send earning to drip contract.
    function _forwardEarning(uint256 earned_) internal virtual {
        if (earned_ > 0) {
            totalEarned += earned_;

            address _dripContract = IVesperPool(pool).poolRewards();
            // Fetches which rewardToken collects the drip
            address _growPool = IEarnDrip(_dripContract).growToken();
            // Checks that the Grow Pool supports dripToken as underlying
            if (_growPool != address(0) && address(IVesperPool(_growPool).token()) == dripToken) {
                uint256 _growPoolBalanceBefore = IERC20(_growPool).balanceOf(address(this));
                IVesperPool(_growPool).deposit(earned_);
                uint256 _growPoolShares = IERC20(_growPool).balanceOf(address(this)) - _growPoolBalanceBefore;
                IERC20(_growPool).safeTransfer(_dripContract, _growPoolShares);
                IEarnDrip(_dripContract).notifyRewardAmount(_growPool, _growPoolShares, dripPeriod);
            } else {
                IERC20(dripToken).safeTransfer(_dripContract, earned_);
                IEarnDrip(_dripContract).notifyRewardAmount(dripToken, earned_, dripPeriod);
            }
        }
    }

    /** @dev Handle collateral profit.
     *      Calculate fee on profit.
     *      Transfer fee to feeCollector
     *      Convert remaining profit into drip token
     *      Forward drip token earning to EarnDrip
     * @param profit_ Profit in collateral
     */
    function _handleProfit(uint256 profit_) internal virtual {
        if (profit_ > 0) {
            uint256 _fee = IVesperPool(pool).calculateUniversalFee(profit_);
            if (_fee > 0) {
                collateralToken.safeTransfer(feeCollector, _fee);
                // Calculated fee will always be less than _profit
                profit_ -= _fee;
            }
            _forwardEarning(_convertCollateralToDrip(profit_));
        }
    }

    /// @dev Approves EarnDrip' Grow token to spend dripToken
    function approveGrowToken() external onlyKeeper {
        address _growPool = IEarnDrip(IVesperPool(pool).poolRewards()).growToken();
        // Checks that the Grow Pool supports dripToken as underlying
        if (_growPool != address(0)) {
            require(address(IVesperPool(_growPool).token()) == dripToken, "invalid-grow-pool");
            IERC20(dripToken).safeApprove(_growPool, 0);
            IERC20(dripToken).safeApprove(_growPool, MAX_UINT_VALUE);
        }
    }

    /**
     * @notice Update update period of distribution of earning done in one rebalance
     * @dev _dripPeriod in seconds
     */
    function updateDripPeriod(uint256 dripPeriod_) external onlyGovernor {
        require(dripPeriod_ > 0, "zero-drip-period");
        require(dripPeriod_ != dripPeriod, "same-drip-period");
        emit DripPeriodUpdated(dripPeriod, dripPeriod_);
        dripPeriod = dripPeriod_;
    }
}