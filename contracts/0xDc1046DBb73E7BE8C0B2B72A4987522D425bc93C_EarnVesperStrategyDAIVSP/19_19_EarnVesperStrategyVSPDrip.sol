// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./EarnVesperStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Earn Vesper Strategy adjusted for vVSP timelock
abstract contract EarnVesperStrategyVSPDrip is EarnVesperStrategy {
    using SafeERC20 for IERC20;

    bool public transferToDripContract = false;

    /**
     * @notice Empty implementation, VSP rewards don't need to be converted.
     */
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {}

    /**
     * @notice Send this earning to drip contract.
     */
    function _forwardEarning() internal override {
        address _dripContract = IVesperPool(pool).poolRewards();
        uint256 _earned = IERC20(dripToken).balanceOf(address(this));
        // Fetches which rewardToken collects the drip
        address _growPool = IEarnDrip(_dripContract).growToken();
        // Checks that the Grow Pool supports dripToken as underlying
        require(address(IVesperPool(_growPool).token()) == dripToken, "invalid-grow-pool");

        if (!transferToDripContract && _earned != 0) {
            totalEarned += _earned;
            IVesperPool(_growPool).deposit(_earned);

            // Next rebalance call will transfer to dripContract
            transferToDripContract = true;
        } else if (transferToDripContract) {
            (, uint256 _interestFee, , , , , , ) = IVesperPool(pool).strategy(address(this));
            uint256 _growPoolShares = IERC20(_growPool).balanceOf(address(this));
            uint256 _fee = (_growPoolShares * _interestFee) / 10000;

            if (_fee != 0) {
                IERC20(_growPool).safeTransfer(feeCollector, _fee);
                _growPoolShares -= _fee;
            }
            IERC20(_growPool).safeTransfer(_dripContract, _growPoolShares);
            IEarnDrip(_dripContract).notifyRewardAmount(_growPool, _growPoolShares, dripPeriod);

            // Next rebalance call will deposit VSP to vVSP Pool
            transferToDripContract = false;
        }
    }
}