// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/vesper/IEarnDrip.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "./Strategy.sol";

abstract contract Earn is Strategy {
    using SafeERC20 for IERC20;

    address public immutable dripToken;

    uint256 public dripPeriod = 48 hours;
    uint256 public totalEarned; // accounting total stable coin earned. This amount is not reported to pool.

    event DripPeriodUpdated(uint256 oldDripPeriod, uint256 newDripPeriod);

    constructor(address _dripToken) {
        require(_dripToken != address(0), "dripToken-zero");
        dripToken = _dripToken;
    }

    /**
     * @notice Update update period of distribution of earning done in one rebalance
     * @dev _dripPeriod in seconds
     */
    function updateDripPeriod(uint256 _dripPeriod) external onlyGovernor {
        require(_dripPeriod != 0, "dripPeriod-zero");
        require(_dripPeriod != dripPeriod, "same-dripPeriod");
        emit DripPeriodUpdated(dripPeriod, _dripPeriod);
        dripPeriod = _dripPeriod;
    }

    /// @dev Approves EarnDrip' Grow token to spend dripToken
    function approveGrowToken() external onlyKeeper {
        address _dripContract = IVesperPool(pool).poolRewards();
        address _growPool = IEarnDrip(_dripContract).growToken();
        // Checks that the Grow Pool supports dripToken as underlying
        require(address(IVesperPool(_growPool).token()) == dripToken, "invalid-grow-pool");
        IERC20(dripToken).safeApprove(_growPool, 0);
        IERC20(dripToken).safeApprove(_growPool, MAX_UINT_VALUE);
    }

    /// @notice Converts excess collateral earned to drip token
    function _convertCollateralToDrip() internal {
        uint256 _collateralAmount = collateralToken.balanceOf(address(this));
        _convertCollateralToDrip(_collateralAmount);
    }

    function _convertCollateralToDrip(uint256 _collateralAmount) internal {
        if (_collateralAmount != 0) {
            uint256 minAmtOut =
                (swapSlippage != 10000)
                    ? _calcAmtOutAfterSlippage(
                        _getOracleRate(_simpleOraclePath(address(collateralToken), dripToken), _collateralAmount),
                        swapSlippage
                    )
                    : 1;
            _safeSwap(address(collateralToken), dripToken, _collateralAmount, minAmtOut);
        }
    }

    /**
     * @notice Send this earning to drip contract.
     */
    function _forwardEarning() internal {
        (, uint256 _interestFee, , , , , , ) = IVesperPool(pool).strategy(address(this));
        address _dripContract = IVesperPool(pool).poolRewards();
        uint256 _earned = IERC20(dripToken).balanceOf(address(this));
        if (_earned != 0) {
            // Fetches which rewardToken collects the drip
            address _growPool = IEarnDrip(_dripContract).growToken();
            // Checks that the Grow Pool supports dripToken as underlying
            require(address(IVesperPool(_growPool).token()) == dripToken, "invalid-grow-pool");
            totalEarned += _earned;
            uint256 _growPoolBalanceBefore = IERC20(_growPool).balanceOf(address(this));
            IVesperPool(_growPool).deposit(_earned);
            uint256 _growPoolShares = IERC20(_growPool).balanceOf(address(this)) - _growPoolBalanceBefore;
            uint256 _fee = (_growPoolShares * _interestFee) / 10000;
            if (_fee != 0) {
                IERC20(_growPool).safeTransfer(feeCollector, _fee);
                _growPoolShares -= _fee;
            }
            IERC20(_growPool).safeTransfer(_dripContract, _growPoolShares);
            IEarnDrip(_dripContract).notifyRewardAmount(_growPool, _growPoolShares, dripPeriod);
        }
    }
}