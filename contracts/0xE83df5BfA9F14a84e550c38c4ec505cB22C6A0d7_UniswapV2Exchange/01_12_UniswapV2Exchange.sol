// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../IExchange.sol";
import "./IUniswapV2.sol";

/**
 * Adapter between IUniswapV2 and TWAP's IExchange interface
 */
contract UniswapV2Exchange is IExchange {
    using SafeERC20 for ERC20;

    IUniswapV2 public immutable uniswap;

    constructor(address _uniswap) {
        uniswap = IUniswapV2(_uniswap);
    }

    /**
     * data = abi encoded: feeOnTransfer(bool), path(address[])
     */
    function getAmountOut(uint256 amountIn, bytes calldata data) public view returns (uint256 amountOut) {
        (, address[] memory path) = decode(data);
        return uniswap.getAmountsOut(amountIn, path)[path.length - 1];
    }

    /**
     * data = abi encoded: feeOnTransfer(bool), path(address[])
     */
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata data
    ) public {
        (bool fotTokens, address[] memory path) = decode(data);
        ERC20 srcToken = ERC20(path[0]);

        srcToken.safeTransferFrom(msg.sender, address(this), amountIn);
        amountIn = srcToken.balanceOf(address(this)); // support FoT tokens

        srcToken.safeIncreaseAllowance(address(uniswap), amountIn);

        if (fotTokens) {
            uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );
        } else {
            uniswap.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp);
        }
    }

    function decode(bytes calldata data) private pure returns (bool fotTokens, address[] memory path) {
        (fotTokens, path) = abi.decode(data, (bool, address[]));
    }
}