// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import '../interfaces/IPYESwapPair.sol';
import '../interfaces/IPYESwapFactory.sol';
import '../interfaces/IToken.sol';
import '../interfaces/IERC20.sol';

import "./SafeMath.sol";

library PYESwapLibrary {

    address constant factory = 0x0fC5F7Ec0fa80933677F63c7b896A26CFC6b76a5;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PYESwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PYESwapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'42b17b9ed6f45899a012923d0f2518a13ffd33f7548e091d1718d57dd3a5c9ce' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,,) = IPYESwapPair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PYESwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, bool tokenFee, bool baseIn, uint totalFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PYESwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInMultiplier = baseIn && tokenFee ? 10000 - totalFee : 10000;
        uint amountInWithFee = amountIn * amountInMultiplier;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 10000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, bool tokenFee, bool baseOut, uint totalFee) internal pure returns (uint, uint) {
        require(amountOut > 0, 'PYESwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountOutMultiplier = tokenFee ? 10000 - totalFee : 10000;
        uint amountOutWithFee = (amountOut * 10000 ) / amountOutMultiplier;
        uint numerator = reserveIn * amountOutWithFee;
        uint denominator = reserveOut - amountOutWithFee;
        uint amountIn = (numerator / denominator) + 1;
        return (amountIn, baseOut ? amountOutWithFee : amountOut);
    }

    function amountsOut(uint amountIn, address[] memory path, uint totalFee) internal view returns (uint[] memory) {
        return getAmountsOut(amountIn, path, totalFee);
    }

    function amountsIn(uint amountOut, address[] memory path, uint totalFee) internal view returns (uint[] memory) {
        return getAmountsIn(amountOut, path, totalFee);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, address[] memory path, uint totalFee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            IPYESwapPair pair = IPYESwapPair(pairFor(path[i], path[i + 1]));
            address baseToken = pair.baseToken();
            bool baseIn = baseToken == path[i] && baseToken != address(0);
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, baseToken != address(0), baseIn, totalFee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, address[] memory path, uint totalFee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            IPYESwapPair pair = IPYESwapPair(pairFor(path[i - 1], path[i]));
            address baseToken = pair.baseToken();
            bool baseOut = baseToken == path[i] && baseToken != address(0);
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
            (amounts[i - 1], amounts[i]) = getAmountIn(amounts[i], reserveIn, reserveOut, baseToken != address(0), baseOut, totalFee);
        }
    }

    function adminFeeCalculation(uint256 _amounts,uint256 _adminFee) internal pure returns (uint256,uint256) {
        uint adminFeeDeduct = (_amounts * _adminFee) / (10000);
        _amounts = _amounts - adminFeeDeduct;

        return (_amounts,adminFeeDeduct);
    }

    function _calculateFees(address _feeCheck, address input, address output, uint amountIn, uint amount0Out, uint amount1Out) internal view returns (uint amount0Fee, uint amount1Fee, uint _amount0Out, uint _amount1Out) {
        IPYESwapPair pair = IPYESwapPair(pairFor(input, output));
        (address token0,) = sortTokens(input, output);
        address baseToken = pair.baseToken();
        address feeTaker = pair.feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(_feeCheck) : 0;
        
        amount0Fee = baseToken != token0 ? uint(0) : input == token0 ? (amountIn * totalFee) / (10**4) : (amount0Out * totalFee) / (10**4);
        amount1Fee = baseToken == token0 ? uint(0) : input != token0 ? (amountIn * totalFee) / (10**4) : (amount1Out * totalFee) / (10**4);
        _amount0Out = amount0Out > 0 ? amount0Out - amount0Fee : amount0Out;
        _amount1Out = amount1Out > 0 ? amount1Out - amount1Fee : amount1Out;
    }

    function _calculateAmounts(address _feeCheck, address input, address output, address token0) internal view returns (uint amountInput, uint amountOutput) {
        IPYESwapPair pair = IPYESwapPair(pairFor(input, output));

        (uint reserve0, uint reserve1,, address baseToken) = pair.getReserves();
        address feeTaker = pair.feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(_feeCheck) : 0;
        bool baseIn = baseToken == input && baseToken != address(0);
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput, baseToken != address(0), baseIn, totalFee);
    }
}