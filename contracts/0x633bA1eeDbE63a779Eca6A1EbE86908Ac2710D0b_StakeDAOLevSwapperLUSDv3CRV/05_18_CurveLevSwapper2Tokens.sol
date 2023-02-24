// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../BaseLevSwapper.sol";
import "../../../interfaces/external/curve/IMetaPool2.sol";
import "../../../utils/Enums.sol";

/// @title CurveLevSwapper2Tokens
/// @author Angle Labs, Inc.
/// @dev Leverage swapper on Curve LP tokens
/// @dev This implementation is for Curve pools with 2 tokens
abstract contract CurveLevSwapper2Tokens is BaseLevSwapper {
    using SafeERC20 for IERC20;

    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) BaseLevSwapper(_core, _uniV3Router, _oneInch, _angleRouter) {
        if (address(metapool()) != address(0)) {
            tokens()[0].safeIncreaseAllowance(address(metapool()), type(uint256).max);
            tokens()[1].safeIncreaseAllowance(address(metapool()), type(uint256).max);
        }
    }

    // =============================== MAIN FUNCTIONS ==============================

    /// @inheritdoc BaseLevSwapper
    function _add(bytes memory) internal override returns (uint256 amountOut) {
        // Instead of doing sweeps at the end just use the full balance to add liquidity
        uint256 amountToken1 = tokens()[0].balanceOf(address(this));
        uint256 amountToken2 = tokens()[1].balanceOf(address(this));
        // Slippage is checked at the very end of the `swap` function
        if (amountToken1 != 0 || amountToken2 != 0) metapool().add_liquidity([amountToken1, amountToken2], 0);
        // Other solution is also to let the user specify how many tokens have been sent + get
        // the return value from `add_liquidity`: it's more gas efficient but adds more verbose
        amountOut = lpToken().balanceOf(address(this));
    }

    /// @inheritdoc BaseLevSwapper
    function _remove(uint256 burnAmount, bytes memory data) internal override {
        CurveRemovalType removalType;
        (removalType, data) = abi.decode(data, (CurveRemovalType, bytes));
        if (removalType == CurveRemovalType.oneCoin) {
            (int128 whichCoin, uint256 minAmountOut) = abi.decode(data, (int128, uint256));
            metapool().remove_liquidity_one_coin(burnAmount, whichCoin, minAmountOut);
        } else if (removalType == CurveRemovalType.balance) {
            uint256[2] memory minAmountOuts = abi.decode(data, (uint256[2]));
            metapool().remove_liquidity(burnAmount, minAmountOuts);
        } else if (removalType == CurveRemovalType.imbalance) {
            (address to, uint256[2] memory amountOuts) = abi.decode(data, (address, uint256[2]));
            metapool().remove_liquidity_imbalance(amountOuts, burnAmount);
            uint256 keptAmount = lpToken().balanceOf(address(this));
            // We may have withdrawn more than needed: maybe not optimal because a user may not want to have
            // lp tokens staked. Solution is to do a sweep on all tokens in the `BaseLevSwapper` contract
            if (keptAmount > 0) angleStaker().deposit(keptAmount, to);
        }
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Reference to the native `tokens` of the Curve pool
    function tokens() public pure virtual returns (IERC20[2] memory);

    /// @notice Reference to the Curve Pool contract
    function metapool() public pure virtual returns (IMetaPool2);

    /// @notice Reference to the actual collateral contract
    /// @dev Most of the time this is the same address as the `metapool`
    function lpToken() public pure virtual returns (IERC20);
}