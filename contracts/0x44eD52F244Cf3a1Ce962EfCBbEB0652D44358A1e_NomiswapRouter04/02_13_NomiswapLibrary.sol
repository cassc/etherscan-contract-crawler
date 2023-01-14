pragma solidity >= 0.8.0;

import '@nominex/stable-swap/contracts/interfaces/INomiswapStablePair.sol';
import '@nominex/stable-swap/contracts/interfaces/INomiswapFactory.sol';

library NomiswapLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'NomiswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'NomiswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        return INomiswapFactory(factory).getPair(tokenA, tokenB);
/*
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'83eb759f5ea0525124f03d4ac741bb4af0bb1c703d5f694bd42a8bd72e495a01' // init code hash
            )))));
*/
    }

    function getSwapFee(address factory, address tokenA, address tokenB) internal view returns (uint swapFee) {
        swapFee = INomiswapPair(pairFor(factory, tokenA, tokenB)).swapFee();
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = INomiswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'NomiswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'NomiswapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getConstantProductAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'NomiswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'NomiswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * (1000 - swapFee);
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getConstantProductAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'NomiswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'NomiswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * (1000 - swapFee);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, address stableSwapFactory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'NomiswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            address pair = INomiswapFactory(stableSwapFactory).getPair(path[i], path[i + 1]);
            if (pair != address(0)) {
                amounts[i + 1] = INomiswapStablePair(pair).getAmountOut(path[i], amounts[i]);
            } else {
                (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
                amounts[i + 1] = getConstantProductAmountOut(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i], path[i + 1]));
            }
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, address stableSwapFactory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'NomiswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            address pair = INomiswapFactory(stableSwapFactory).getPair(path[i - 1], path[i]);
            if (pair != address(0)) {
                amounts[i - 1] = INomiswapStablePair(pair).getAmountIn(path[i - 1], amounts[i]);
            } else {
                (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
                amounts[i - 1] = getConstantProductAmountIn(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i - 1], path[i]));
            }
        }
    }
    
}