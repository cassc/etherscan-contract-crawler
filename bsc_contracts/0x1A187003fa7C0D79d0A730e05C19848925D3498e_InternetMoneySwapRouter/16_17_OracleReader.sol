// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

abstract contract OracleReader {
    using Address for address;
    // fee = 0.729% Fee
    uint256 public constant feeDenominator = 100_000;
    uint256 public immutable fee;
    /**
     * the native address to deposit and withdraw from in the swap methods
     * @notice this address cannot be updated after it is set during constructor
     */
    address payable public immutable wNative;
    constructor(address payable _wNative, uint96 _fee) {
        wNative = _wNative;
        fee = _fee;
    }
    /**
     * checks the exchange factory pair for a pair with weth and its reserves
     * @param factory the factory to check for a pair and fee of the market
     * @param _amountIn the amount to simulate trading through the market
     * @param path the tokens being traded from and to
     */
    function getFeeMinimum(
        address factory,
        uint256 _amountIn,
        address[] calldata path
    ) public view returns(address, uint256) {
        for (uint256 i = 0; i < path.length; ++i) {
            address target = path[i];
            uint256 minimum = getSingleFeeMinimum(factory, _amountIn, target);
            if (minimum > 0) {
                return (target, minimum);
            }
            if (i != path.length - 1) {
                _amountIn = amountOutFrom(factory, target, path[i + 1], _amountIn);
            }
        }
        return (address(0), 0);
    }

    /**
     * get the amount out from reserves
     * does not take into account fees charged along the way
     * @param factory the factory to derive a pair against
     * @param tokenIn the token being pushed into the pair
     * @param tokenOut the token to be pulled out
     * @param amountIn the magnitude of the swap
     */
    function amountOutFrom(address factory, address tokenIn, address tokenOut, uint256 amountIn) public view returns(uint256) {
        address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        bool inIs0 = IUniswapV2Pair(pair).token0() == tokenIn;
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(pair).getReserves();
        if (inIs0) {
            return (reserveB * amountIn) / reserveA;
        }
        return (reserveA * amountIn) / reserveB;
    }

    /**
     * gets the fee for a single token from the exchange factory pair
     * @param factory the factory to check for a pair
     * @param _amountIn the amount of tokens being moved through the market
     * @param source the token to check against wNative
     * @notice the number returned from this method does not check
     * the fee for the market so the calculation will be off by ~0.3% for most markets
     */
    function getSingleFeeMinimum(
        address factory,
        uint256 _amountIn,
        address source
    ) public view returns(uint256 minimum) {
        (uint256 tokenAmount, uint256 wethAmount) = checkPairForValidPrice(factory, source);
        if (wethAmount > 1 ether) {
            return (_amountIn * wethAmount * fee) / (feeDenominator * tokenAmount);
        }
    }

    /**
     * pull a token and weth reserve out of a provided token and factory to derive a market
     * @param factory the address of the factory to derive a pair from (token + wNative)
     * @param token the token to derive against a wNative token
     * @return tokenReserve the amount of token in reserve
     * @return wethReserve the amount of weth in reserve
     */
    function checkPairForValidPrice(address factory, address token) public view returns(uint256 tokenReserve, uint256 wethReserve) {
        IUniswapV2Factory uniFactory = IUniswapV2Factory(factory);
        address _wNative = wNative;
        address pair = uniFactory.getPair(token, _wNative);
        if (pair.isContract()) {
            (uint256 _reserveA, uint256 _reserveB, ) = IUniswapV2Pair(pair).getReserves();
            address token0 = IUniswapV2Pair(pair).token0();
            bool zeroIsWeth = token0 == _wNative;
            tokenReserve = zeroIsWeth ? _reserveB : _reserveA;
            wethReserve = zeroIsWeth ? _reserveA : _reserveB;
        }
        // weth is always returned as denominator
    }
}