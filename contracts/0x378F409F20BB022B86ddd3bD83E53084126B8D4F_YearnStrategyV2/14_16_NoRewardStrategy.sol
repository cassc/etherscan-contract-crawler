// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ProcessStrategy.sol";

/**
 * @notice No reward strategy logic
 */
abstract contract NoRewardStrategy is ProcessStrategy {
    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Set initial values
     * @param _underlying Underlying asset
     * @param _processSlippageSlots Slots for processing
     * @param _reallocationSlippageSlots Slots for reallocation
     * @param _depositSlippageSlots Slots for deposits
     * @param _doValidateBalance Force balance validation
     */
    constructor(
        IERC20 _underlying,
        uint256 _processSlippageSlots,
        uint256 _reallocationSlippageSlots,
        uint256 _depositSlippageSlots,
        bool _doValidateBalance,
        address _self
    )
        BaseStrategy(
            _underlying,
            0,
            _processSlippageSlots,
            _reallocationSlippageSlots,
            _depositSlippageSlots,
            false,
            _doValidateBalance,
            _self
        )
    {}

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Returns total strategy balance including pending rewards
     * @return strategyBalance total strategy balance including pending rewards
     */
    function _getStrategyUnderlyingWithRewards() internal view override virtual returns(uint128) {
        return getStrategyBalance();
    }

    /**
     * @notice Process rewards - not supported
     */
    function _processRewards(SwapData[] calldata) internal pure override {
        revert("NoRewardStrategy::_processRewards: Strategy does not have rewards");
    }

    /**
     * @notice Process fast withdraw
     * @param shares Amount of shares
     * @param slippages Slippages array
     * @return withdrawnAmount Underlying withdrawn amount
     */
    function _processFastWithdraw(uint128 shares, uint256[] memory slippages, SwapData[] calldata) internal virtual override returns(uint128) {
        return _withdraw(shares, slippages);
    }

    function _validateRewardsSlippage(SwapData[] calldata) internal view override {}
}