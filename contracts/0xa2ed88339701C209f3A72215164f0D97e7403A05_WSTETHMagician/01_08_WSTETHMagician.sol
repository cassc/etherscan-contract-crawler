// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./_common/STETHBaseMagician.sol";
import "./interfaces/IWETH9Like.sol";
import "./interfaces/ISTETHLike2.sol";

/// @dev wstETH Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
contract WSTETHMagician is STETHBaseMagician {
    /// @dev Revert if `towardsNative` or `towardsAsset` has been executed for an asset other than `wstETH`
    error InvalidAsset();

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(WSTETH)) {
            revert InvalidAsset();
        }

        uint256 stETHAmount = WSTETH.unwrap(_amount);

        return (STETH, stETHAmount);
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(WSTETH)) {
            revert InvalidAsset();
        }

        // calculate a price wstETH -> stETH
        uint256 stETHAmountRequired;
        // We have to add 1 wei to get the exact amount of stETH that we need,
        // as we lost it in the `getPooledEthByShares` function because of the solidity precision error on the division
        unchecked { stETHAmountRequired = ISTETHLike2(STETH).getPooledEthByShares(_amount) + 1 wei; }

        // calculate a price stETH -> ETH 
        (uint256 requiredETH, uint256 expectedStEthAmount) = _calcRequiredETH(stETHAmountRequired);

        // Un wrap required amount of ETH (WETH -> ETH)
        IWETH9Like(WETH).withdraw(requiredETH);

        // exchange ETH -> stETH
        uint256 stETHReceived = CURVE_POOL.exchange{value: requiredETH}(
            ETH_INDEX,
            STETH_INDEX,
            requiredETH,
            expectedStEthAmount
        );

        IERC20(STETH).approve(address(WSTETH), stETHReceived);

        // Wrap stETH -> wstETH
        WSTETH.wrap(stETHReceived);

        return (address(WSTETH), requiredETH);
    }
}