// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../swaps/HelixPair.sol";

library HelixLibrary {
    modifier notZeroAmount(uint256 amount) {
        require(amount > 0, "HelixLibrary: zero amount");
        _;
    }

    modifier notZeroLiquidity(uint256 liquidity) {
        require(liquidity > 0, "HelixLibrary: zero liquidity");
        _;
    }

    modifier isValidPath(address[] memory path) {
        require(path.length >= 2, "HelixLibrary: invalid path");
        _;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) 
        internal 
        pure 
        returns (address token0, address token1) 
    {
        require(tokenA != tokenB, "HelixLibrary: identical addresses");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "HelixLibrary: zero address");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) 
        internal 
        pure 
        returns (address pair) 
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                // hex"c982a01a3d96a6bfb7f46c8cdfa12bbe67c0deeaac07310f3cc6327e92f7fbce" // ropsten
                // hex"368552104b0dcaacb939b1fe4370f68e358d806ee5d5c9a95193874dd004841a" // rinkeby
                hex"df06dacc3c0f420f3e881baed6af2087e5ab8bc910d926f439c1081ec11fc885" // mainnet
            )))));
    }

    function getSwapFee(address factory, address tokenA, address tokenB) 
        internal 
        view 
        returns (uint256 swapFee) 
    {
        swapFee = HelixPair(pairFor(factory, tokenA, tokenB)).swapFee();
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = HelixPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) 
        internal 
        pure 
        notZeroAmount(amountA) 
        notZeroLiquidity(reserveA)
        notZeroLiquidity(reserveB)
        returns (uint256 amountB) 
    {
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 swapFee) 
        internal 
        pure 
        notZeroAmount(amountIn) 
        notZeroLiquidity(reserveIn)
        notZeroLiquidity(reserveOut)
        returns (uint256 amountOut) 
    {
        uint256 amountInWithFee = amountIn * (uint(1000) - swapFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut, uint256 swapFee) 
        internal 
        pure 
        notZeroAmount(amountOut) 
        notZeroLiquidity(reserveIn)
        notZeroLiquidity(reserveOut)
        returns (uint256 amountIn) 
    {
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * (uint(1000) - swapFee);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) 
        internal 
        view 
        isValidPath(path)
        returns (uint[] memory amounts) 
    {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        uint256 length = path.length - 1;
        for (uint256 i; i < length; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i], path[i + 1]));
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) 
        internal 
        view 
        isValidPath(path)
        returns (uint[] memory amounts) 
    {
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        uint256 length = path.length - 1;
        for (uint256 i = length; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i - 1], path[i]));
        }
    }   
}