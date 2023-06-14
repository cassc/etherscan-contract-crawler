// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/uniswap-v3/ISwapRouter.sol";
import "../interfaces/uniswap-v3/IUniswapV3Pool.sol";
import "../interfaces/uniswap-v3/PoolAddress.sol";
import "../interfaces/uniswap-v3/Path.sol";

import "./SafeMathExtends.sol";

pragma abicoder v2;

/// @title UniV3 Swap extends libraries
/// @notice libraries
library UniV3SwapExtends {

    using Path for bytes;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;

    //x96
    uint256 constant internal x96 = 2 ** 96;

    //fee denominator
    uint256 constant internal denominator = 1000000;

    //Swap Router
    ISwapRouter constant internal SRT = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice Estimated to obtain the target token amount
    /// @dev Only allow the asset transaction path that has been set to be estimated
    /// @param self Mapping path
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountIn Source token amount
    /// @return amountOut Target token amount
    function estimateAmountOut(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountIn
    ) internal view returns (uint256 amountOut){
        if (amountIn == 0) {return 0;}
        bytes memory path = self[from][to];
        amountOut = amountIn;
        while (true) {
            (address fromToken, address toToken, uint24 fee) = path.getFirstPool().decodeFirstPool();
            address _pool = PoolAddress.getPool(fromToken, toToken, fee);
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(_pool).slot0();
            address token0 = fromToken < toToken ? fromToken : toToken;
            amountOut = amountOut.mul(denominator.sub(uint256(fee))).div(denominator);
            if (token0 == toToken) {
                amountOut = amountOut.sqrt().mul(x96).div(sqrtPriceX96) ** 2;
            } else {
                amountOut = amountOut.sqrt().mul(sqrtPriceX96).div(x96) ** 2;
            }
            bool hasMultiplePools = path.hasMultiplePools();
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                break;
            }
        }
    }

    /// @notice Estimate the amount of source tokens that need to be provided
    /// @dev Only allow the governance identity to set the underlying asset token address
    /// @param self Mapping path
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountOut Expected target token amount
    /// @return amountIn Source token amount
    function estimateAmountIn(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountOut
    ) internal view returns (uint256 amountIn){
        if (amountOut == 0) {return 0;}
        bytes memory path = self[from][to];
        amountIn = amountOut;
        while (true) {
            (address fromToken, address toToken, uint24 fee) = path.getFirstPool().decodeFirstPool();
            address _pool = PoolAddress.getPool(fromToken, toToken, fee);
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(_pool).slot0();
            address token0 = fromToken < toToken ? fromToken : toToken;
            if (token0 == toToken) {
                amountIn = amountIn.sqrt().mul(sqrtPriceX96).div(x96) ** 2;
            } else {
                amountIn = amountIn.sqrt().mul(x96).div(sqrtPriceX96) ** 2;
            }
            amountIn = amountIn.mul(denominator).div(denominator.sub(uint256(fee)));
            bool hasMultiplePools = path.hasMultiplePools();
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                break;
            }
        }
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Initiate a transaction with a known input amount and return the output amount
    /// @param self Mapping path
    /// @param from Input token address
    /// @param to Output token address
    /// @param amountIn Token in amount
    /// @param recipient Recipient address
    /// @param amountOutMinimum Expected to get minimum token out amount
    /// @return Token out amount
    function exactInput(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountIn,
        address recipient,
        uint256 amountOutMinimum
    ) internal returns (uint256){
        bytes memory path = self[from][to];
        return SRT.exactInput(
            ISwapRouter.ExactInputParams({
        path : path,
        recipient : recipient,
        deadline : block.timestamp,
        amountIn : amountIn,
        amountOutMinimum : amountOutMinimum
        }));
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @dev Initiate a transaction with a known output amount and return the input amount
    /// @param self Mapping path
    /// @param from Input token address
    /// @param to Output token address
    /// @param recipient Recipient address
    /// @param amountOut Token out amount
    /// @param amountInMaximum Expect to input the maximum amount of tokens
    /// @return Token in amount
    function exactOutput(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        address recipient,
        uint256 amountOut,
        uint256 amountInMaximum
    ) internal returns (uint256){
        bytes memory path = self[to][from];
        return SRT.exactOutput(
            ISwapRouter.ExactOutputParams({
        path : path,
        recipient : recipient,
        deadline : block.timestamp,
        amountOut : amountOut,
        amountInMaximum : amountInMaximum
        }));
    }
}