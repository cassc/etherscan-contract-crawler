// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IWETH9Like.sol";
import "./_common/STETHBaseMagician.sol";

/// @dev stETH Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
contract STETHMagician is STETHBaseMagician {
    error InvalidAsset();

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(STETH)) {
            revert InvalidAsset();
        }

        IERC20(STETH).approve(address(CURVE_POOL), _amount);

        tokenOut = WETH;
        uint256 minAmountOut = 1;
        amountOut = CURVE_POOL.exchange(STETH_INDEX, ETH_INDEX, _amount, minAmountOut);

        // Wrap ETH
        IWETH9Like(WETH).deposit{value: amountOut}();
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != STETH) {
            revert InvalidAsset();
        }

        // calculate a price stETH -> ETH 
        (uint256 requiredETH, uint256 expectedStEthAmount) = _calcRequiredETH(_amount);

        // Un wrap required amount of ETH (WETH -> ETH)
        IWETH9Like(WETH).withdraw(requiredETH);

        // exchange ETH -> stETH
        CURVE_POOL.exchange{value: requiredETH}(
            ETH_INDEX,
            STETH_INDEX,
            requiredETH,
            expectedStEthAmount
        );

        return (STETH, requiredETH);
    }
}