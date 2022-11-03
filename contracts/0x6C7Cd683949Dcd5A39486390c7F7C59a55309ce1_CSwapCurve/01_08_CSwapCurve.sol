// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "ICryptoPool.sol";
import "ICSwapCurve.sol";
import "ICurvePool.sol";
import "CSwapBase.sol";

contract CSwapCurve is CSwapBase, ICSwapCurve {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _getContractName() internal pure override returns (string memory) {
        return "CSwapCurve";
    }

    function _preSwap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address router,
        uint256 amount,
        address receiver
    ) internal override returns (uint256 balanceBefore) {
        if (address(tokenOut) == ETH_ADDRESS) {
            balanceBefore = address(receiver).balance;
        } else {
            balanceBefore = tokenOut.balanceOf(address(receiver));
        }
        if (address(tokenIn) != ETH_ADDRESS) {
            _tokenApprove(tokenIn, router, amount);
        }
    }

    function _postSwap(
        uint256 balanceBefore,
        IERC20 tokenOut,
        uint256 minReceived,
        address receiver
    ) internal override {
        uint256 balanceAfter;
        if (address(tokenOut) == ETH_ADDRESS) {
            balanceAfter = address(receiver).balance;
        } else {
            balanceAfter = tokenOut.balanceOf(address(receiver));
        }
        _requireMsg(balanceAfter >= balanceBefore + minReceived, "Slippage in");
    }

    /** @notice Use this function to SELL a fixed amount of an asset.
        @dev This function sells an EXACT amount of `tokenIn` to receive `tokenOut`.
        If the price is worse than a threshold, the transaction will revert.
        @param amountIn The exact amount of `tokenIn` to sell.
        @param tokenIn The token to sell. Note: This must be an ERC20 token.
        @param tokenOut The token that the user wishes to receive. Note: This must be an ERC20 token.
        @param minAmountOut The minimum amount of `tokenOut` the user wishes to receive.
        @param params Additional parameters to specify Curve specific parameters. See ICSwapCurve.sol
     */
    function sell(
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        CurveSwapParams calldata params
    ) external payable {
        uint256 balanceBefore = _preSwap(
            tokenIn,
            tokenOut,
            params.poolAddress,
            amountIn,
            address(this)
        );
        uint256 ethAmount;

        if (address(tokenIn) == ETH_ADDRESS) {
            ethAmount = amountIn;
        }

        if (params.swapType == CurveSwapType.STABLESWAP_EXCHANGE) {
            // Stableswap `exchange`
            ICurvePool(params.poolAddress).exchange{value: ethAmount}(
                int128(int256(params.tokenI)),
                int128(int256(params.tokenJ)),
                amountIn,
                minAmountOut
            );
        } else if (params.swapType == CurveSwapType.STABLESWAP_UNDERLYING) {
            // Stableswap `exchange_underlying`
            ICurvePool(params.poolAddress).exchange_underlying{value: ethAmount}(
                int128(int256(params.tokenI)),
                int128(int256(params.tokenJ)),
                amountIn,
                minAmountOut
            );
        } else if (params.swapType == CurveSwapType.CRYPTOSWAP_EXCHANGE) {
            // Cryptoswap `exchange`
            ICryptoPool(params.poolAddress).exchange{value: ethAmount}(
                params.tokenI,
                params.tokenJ,
                amountIn,
                minAmountOut
            );
        } else if (params.swapType == CurveSwapType.CRYPTOSWAP_UNDERLYING) {
            // Cryptoswap `exchange_underlying`
            ICryptoPool(params.poolAddress).exchange_underlying{value: ethAmount}(
                params.tokenI,
                params.tokenJ,
                amountIn,
                minAmountOut
            );
        } else {
            _revertMsg("Unknown swapType");
        }

        _postSwap(balanceBefore, tokenOut, minAmountOut, address(this));
    }

    /** @notice Function not implemented by choice
        @dev It is not possible to specify an EXACT number of tokens to buy using curve.
     */
    function buy(
        uint256 amountOut,
        IERC20 tokenOut,
        IERC20 tokenIn,
        uint256 maxAmountIn,
        CurveSwapParams calldata params
    ) external payable {
        _revertMsg("buy not supported");
    }
}