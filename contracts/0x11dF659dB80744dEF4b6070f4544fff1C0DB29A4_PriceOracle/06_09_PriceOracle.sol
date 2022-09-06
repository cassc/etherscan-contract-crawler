// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV3Factory} from "../intergrations/uniswap/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../intergrations/uniswap/IUniswapV3Pool.sol";
import {OracleLibrary, FullMath} from "../intergrations/uniswap/libraries/OracleLibrary.sol";
import {FixedPoint128} from "../intergrations/uniswap/libraries/FixedPoint128.sol";

contract PriceOracle is Ownable {
    IUniswapV3Factory public immutable factory;
    address public immutable wethAddress;
    uint32 public pricePeriod = 60;
    uint24[] public fees = [500, 3000, 10000];

    // Contract version
    uint256 public constant version = 1;

    // token/ETH (or ETH/token) pool
    mapping(address => address) private _pools;

    constructor(IUniswapV3Factory _factory, address _weth) {
        factory = _factory;
        wethAddress = _weth;
    }

    function convertToETH(address token, uint256 amount) public view returns (uint256) {
        if (token == wethAddress) return amount;

        address pool = getPool(token, wethAddress);
        int24 tick = getArithmeticMeanTick(pool);
        return OracleLibrary.getQuoteAtTick(tick, uint128(amount), token, wethAddress);
    }

    function convert(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        if (tokenIn == tokenOut || amountIn == 0) return amountIn;

        address pool = getPool(tokenIn, tokenOut);
        if (pool != address(0)) {
            int24 tick = getArithmeticMeanTick(pool);
            return OracleLibrary.getQuoteAtTick(tick, uint128(amountIn), tokenIn, tokenOut);
        } else {
            address pool0 = getPool(tokenIn, wethAddress);
            int24 tick0 = getArithmeticMeanTick(pool0);
            uint256 amount = OracleLibrary.getQuoteAtTick(tick0, uint128(amountIn), tokenIn, wethAddress);

            address pool1 = getPool(tokenOut, wethAddress);
            int24 tick1 = getArithmeticMeanTick(pool1);
            return OracleLibrary.getQuoteAtTick(tick1, uint128(amount), wethAddress, tokenOut);
        }
    }

    function getPool(address token0, address token1) public view returns (address) {
        if (token0 == wethAddress) return getTokenETHPool(token1);
        if (token1 == wethAddress) return getTokenETHPool(token0);
        return getLargestPool(token0, token1);
    }

    function getTokenETHPool(address token) public view returns (address) {
        address pool = _pools[token];
        if (pool != address(0)) return pool;
        return getLargestPool(token, wethAddress);
    }

    function getArithmeticMeanTick(address pool) internal view returns (int24 tick) {
        uint32 oldest = OracleLibrary.getOldestObservationSecondsAgo(pool);
        uint32 secondsAgo = oldest < pricePeriod ? oldest : pricePeriod;
        if (secondsAgo == 0) {
            (, tick, , , , , ) = IUniswapV3Pool(pool).slot0();
        } else {
            (tick, ) = OracleLibrary.consult(pool, secondsAgo);
        }
    }

    function getLargestPool(address token0, address token1) internal view returns (address pool) {
        address temp;
        uint256 maxLiquidity;
        for (uint256 i = 0; i < fees.length; i++) {
            temp = factory.getPool(token0, token1, fees[i]);
            if (temp == address(0)) continue;
            uint256 liquidity = IUniswapV3Pool(temp).liquidity();
            if (liquidity > maxLiquidity) {
                maxLiquidity = liquidity;
                pool = temp;
            }
        }
    }

    function enableFeeAmount(uint24 fee) external onlyOwner {
        require(fee < 1000000);
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i] == fee) revert();
        }
        fees.push(fee);
    }

    function setPricePeriod(uint32 period) external onlyOwner {
        pricePeriod = period;
    }

    function setPool(address token, address poolAddress) external onlyOwner {
        uint24 fee = IUniswapV3Pool(poolAddress).fee();
        require(factory.getPool(token, wethAddress, fee) == poolAddress);

        _pools[token] = poolAddress;
    }
}