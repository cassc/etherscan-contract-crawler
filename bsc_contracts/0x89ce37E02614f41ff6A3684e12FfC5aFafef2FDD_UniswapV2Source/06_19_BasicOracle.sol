// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./interfaces/IOracle.sol";
import "./interfaces/UniswapV2/IUniswapV2Factory.sol";
import "./interfaces/UniswapV2/IUniswapV2Pair.sol";
import "./interfaces/UniswapV3/IUniswapV3Factory.sol";
import "./interfaces/UniswapV3/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/TickMath.sol";
import "hardhat/console.sol";

contract UniswapV3Source is IOracle {
    IUniswapV3Factory factory;
    address[] commonPoolTokens;

    constructor(address _factory, address[] memory _commonPoolTokens) {
        factory = IUniswapV3Factory(_factory);
        commonPoolTokens = _commonPoolTokens;
    }

    function getSqrtTwapX96(address uniswapV3Pool, uint32 twapInterval) public view returns (uint160 sqrtPriceX96) {
        if (twapInterval == 0) {
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval;
            secondsAgos[1] = 0;
            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(twapInterval)))
            );
        }
    }

    function getPrice1X96FromSqrtPriceX96(
        uint160 sqrtPriceX96,
        uint256 decimals
    ) public pure returns (uint256 priceX96) {
        uint256 MAX_INT = 2 ** 256 - 1;
        if (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) > MAX_INT / 1e18) {
            return decimals * ((uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> (96 * 2));
        } else {
            return ((decimals * uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> (96 * 2));
        }
    }

    function getPrice0X96FromSqrtPriceX96(
        uint160 sqrtPriceX96,
        uint256 decimals
    ) public pure returns (uint256 priceX96) {
        return (decimals * 2 ** 192) / (uint256(sqrtPriceX96) ** 2);
    }

    function getMainPair(address token0, address token1) public view returns (address) {
        uint16[4] memory availableFees = [100, 500, 3000, 10000];
        uint256 maxLiquidity = 0;
        address mainPool;
        for (uint256 i = 0; i < availableFees.length; i++) {
            address poolAddress = factory.getPool(token0, token1, availableFees[i]);
            if (poolAddress != address(0)) {
                uint256 liquidity = IUniswapV3Pool(poolAddress).liquidity();
                if (liquidity > maxLiquidity) {
                    maxLiquidity = liquidity;
                    mainPool = poolAddress;
                }
            }
        }
        return mainPool;
    }

    function getPrice(address token, address inTermsOf) public view returns (uint256) {
        address mainPool = getMainPair(token, inTermsOf);
        if (mainPool != address(0)) {
            IUniswapV3Pool pool = IUniswapV3Pool(mainPool);
            uint160 sqrtTwapX96 = getSqrtTwapX96(mainPool, 60);
            if (token == pool.token0()) {
                return getPrice1X96FromSqrtPriceX96(sqrtTwapX96, uint256(10) ** ERC20(token).decimals());
            } else {
                return getPrice0X96FromSqrtPriceX96(sqrtTwapX96, uint256(10) ** ERC20(token).decimals());
            }
        }
        for (uint256 i = 0; i < commonPoolTokens.length; i++) {
            address poolAddress = getMainPair(token, commonPoolTokens[i]);
            if (poolAddress != address(0)) {
                IUniswapV3Pool pair = IUniswapV3Pool(poolAddress);
                uint256 priceOfCommonPoolToken = getPrice(commonPoolTokens[i], inTermsOf);
                uint256 priceIntermediate;
                uint160 sqrtTwapX96 = getSqrtTwapX96(poolAddress, 60);
                if (token == pair.token0()) {
                    priceIntermediate = getPrice1X96FromSqrtPriceX96(
                        sqrtTwapX96,
                        uint256(10) ** ERC20(token).decimals()
                    );
                } else {
                    priceIntermediate = getPrice0X96FromSqrtPriceX96(
                        sqrtTwapX96,
                        uint256(10) ** ERC20(token).decimals()
                    );
                }
                return
                    (priceIntermediate * priceOfCommonPoolToken) / uint256(10) ** ERC20(commonPoolTokens[i]).decimals();
            }
        }
        return 0;
    }
}

contract UniswapV2Source is IOracle {
    IUniswapV2Factory factory;
    address[] commonPoolTokens;

    constructor(address _factory, address[] memory _commonPoolTokens) {
        factory = IUniswapV2Factory(_factory);
        commonPoolTokens = _commonPoolTokens;
    }

    function getPrice(address token, address inTermsOf) public view returns (uint256) {
        address poolAddress = factory.getPair(token, inTermsOf);
        if (poolAddress != address(0)) {
            IUniswapV2Pair pair = IUniswapV2Pair(poolAddress);
            (uint256 r0, uint256 r1, ) = pair.getReserves();
            if (token == pair.token0()) {
                return ((r1 * uint256(10) ** ERC20(token).decimals()) / r0);
            } else {
                return ((r0 * uint256(10) ** ERC20(token).decimals()) / r1);
            }
        }
        for (uint256 i = 0; i < commonPoolTokens.length; i++) {
            poolAddress = factory.getPair(token, commonPoolTokens[i]);
            if (poolAddress != address(0)) {
                IUniswapV2Pair pair = IUniswapV2Pair(poolAddress);
                uint256 priceOfCommonPoolToken = getPrice(commonPoolTokens[i], inTermsOf);
                (uint256 r0, uint256 r1, ) = pair.getReserves();
                uint256 priceIntermediate;
                if (token == pair.token0()) {
                    priceIntermediate = ((r1 * uint256(10) ** ERC20(token).decimals()) / r0);
                } else {
                    priceIntermediate = ((r0 * uint256(10) ** ERC20(token).decimals()) / r1);
                }
                return
                    (priceIntermediate * priceOfCommonPoolToken) / uint256(10) ** ERC20(commonPoolTokens[i]).decimals();
            }
        }
        return 0;
    }
}

contract BasicOracle is IOracle, Ownable {
    IOracle[] public sources;

    constructor(IOracle[] memory _sources) {
        sources = _sources;
    }

    function setSources(IOracle[] memory _sources) external onlyOwner {
        sources = _sources;
    }

    function _calculateMean(uint256[] memory prices) internal pure returns (uint256) {
        uint256 total;
        uint256 numPrices;
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] > 0) {
                total += prices[i];
                numPrices += 1;
            }
        }
        require(numPrices > 0, "5");
        return total / numPrices;
    }

    function getPrice(address token, address inTermsOf) external view returns (uint256) {
        if (token == inTermsOf) return (10 ** ERC20(token).decimals());
        uint256[] memory prices = new uint256[](sources.length);
        for (uint256 i = 0; i < sources.length; i++) {
            prices[i] = sources[i].getPrice(token, inTermsOf);
        }
        return _calculateMean(prices);
    }

    function getPrice2(address token, address inTermsOf) external returns (uint256) {
        if (token == inTermsOf) return (10 ** ERC20(token).decimals());
        uint256[] memory prices = new uint256[](sources.length);
        for (uint256 i = 0; i < sources.length; i++) {
            prices[i] = sources[i].getPrice(token, inTermsOf);
        }
        return _calculateMean(prices);
    }
}