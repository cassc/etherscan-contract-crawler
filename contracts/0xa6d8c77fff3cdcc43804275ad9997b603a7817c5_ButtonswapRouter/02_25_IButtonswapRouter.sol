// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IETHButtonswapRouter} from "./IETHButtonswapRouter.sol";

interface IButtonswapRouter is IETHButtonswapRouter {
    /**
     * @notice Returns the Pair contract for given tokens. Returns the zero address if no pair exists
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return pair The pair address
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Returns the factory state of `isCreationRestricted`
     * @return _isCreationRestricted The `isCreationRestricted` state of the factory.
     */
    function isCreationRestricted() external view returns (bool _isCreationRestricted);

    /**
     * @notice Given some amount of an asset and pair pools, returns an equivalent amount of the other asset
     * @param amountA The amount of token A
     * @param poolA The balance of token A in the pool
     * @param poolB The balance of token B in the pool
     * @return amountB The amount of token B
     */
    function quote(uint256 amountA, uint256 poolA, uint256 poolB) external pure returns (uint256 amountB);

    /**
     * @notice Given an input amount of an asset and pair pools, returns the maximum output amount of the other asset
     * Factors in the fee on the input amount.
     * @param amountIn The input amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountOut The output amount of the other asset
     */
    function getAmountOut(uint256 amountIn, uint256 poolIn, uint256 poolOut)
        external
        pure
        returns (uint256 amountOut);

    /**
     * @notice Given an output amount of an asset and pair pools, returns a required input amount of the other asset
     * @param amountOut The output amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountIn The required input amount of the other asset
     */
    function getAmountIn(uint256 amountOut, uint256 poolIn, uint256 poolOut) external pure returns (uint256 amountIn);

    /**
     * @notice Given an ordered array of tokens and an input amount of the first asset, performs chained getAmountOut calculations to calculate the output amount of the final asset
     * @param amountIn The input amount of the first asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The output amounts of each asset in the path
     */
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    /**
     * @notice Given an ordered array of tokens and an output amount of the final asset, performs chained getAmountIn calculations to calculate the input amount of the first asset
     * @param amountOut The output amount of the final asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The input amounts of each asset in the path
     */
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    /**
     * @notice Returns how much of the much of mintAmountA will be swapped for tokenB and for how much during a mintWithReservoir operation.
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param mintAmountA The amount of tokenA to be minted
     * @return tokenAToSwap The amount of tokenA to be exchanged for tokenB from the reservoir
     * @return swappedReservoirAmountB The amount of tokenB returned from the reservoir
     */
    function getMintSwappedAmounts(address tokenA, address tokenB, uint256 mintAmountA)
        external
        view
        returns (uint256 tokenAToSwap, uint256 swappedReservoirAmountB);

    /**
     * @notice Returns how much of tokenA will be withdrawn from the pair and how much of it came from the reservoir during a burnFromReservoir operation.
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param liquidity The amount of liquidity to be burned
     * @return tokenOutA The amount of tokenA to be withdrawn from the pair
     * @return swappedReservoirAmountA The amount of tokenA returned from the reservoir
     */
    function getBurnSwappedAmounts(address tokenA, address tokenB, uint256 liquidity)
        external
        view
        returns (uint256 tokenOutA, uint256 swappedReservoirAmountA);
}