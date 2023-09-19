// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IUniswapV3Pool } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import { OracleLibrary } from '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';

import { IERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol';
import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';

import { Registry } from '../registry/Registry.sol';

import { IValioCustomAggregator } from './IValioCustomAggregator.sol';
import { IAggregatorV3Interface } from '../interfaces/IAggregatorV3Interface.sol';

contract UniswapV3TWAPAggregator is SafeOwnable, IValioCustomAggregator {
    struct V3PoolConfig {
        IUniswapV3Pool pool;
        address pairToken;
    }

    Registry public immutable VALIO_REGISTRY;
    // Number of seconds in the past from which to calculate the time-weighted means
    uint32 public immutable SECONDS_AGO;
    // Configure on a per chain basis, based on number of blocks per minute
    uint public immutable CARDINALITY_PER_MINUTE;

    mapping(address => V3PoolConfig) public assetToV3PoolConfig;

    constructor(
        address _VALIO_REGISTRY,
        uint32 _SECONDS_AGO,
        uint _CARDINALITY_PER_MINUTE
    ) {
        _setOwner(msg.sender);
        VALIO_REGISTRY = Registry(_VALIO_REGISTRY);
        SECONDS_AGO = _SECONDS_AGO;
        CARDINALITY_PER_MINUTE = _CARDINALITY_PER_MINUTE;
    }

    function setV3Pool(address asset, IUniswapV3Pool pool) external onlyOwner {
        address pairToken = pool.token0();
        if (asset == pairToken) {
            pairToken = pool.token1();
        }
        // Must have a real aggregator for the pairedToken
        require(
            address(VALIO_REGISTRY.chainlinkV3USDAggregators(pairToken)) !=
                address(0),
            'no pair aggregator'
        );

        assetToV3PoolConfig[asset] = V3PoolConfig(pool, pairToken);
        _prepareCardinality(pool, SECONDS_AGO);
        // Make a call to check the pool is valid
        (int answer, ) = _latestRoundData(asset);
        require(answer > 0, 'invalid answer');
    }

    function latestRoundData(
        address mainToken
    ) external view override returns (int256 answer, uint256 updatedAt) {
        return _latestRoundData(mainToken);
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return 'UniswapV3TWAPAggregator';
    }

    function _prepareCardinality(IUniswapV3Pool pool, uint32 period) internal {
        // We add 1 just to be on the safe side
        uint16 cardinality = uint16((period * CARDINALITY_PER_MINUTE) / 60) + 1;
        IUniswapV3Pool(pool).increaseObservationCardinalityNext(cardinality);
    }

    /// @notice Get the latest price from the twap
    /// @return answer The price 10**8
    /// @return updatedAt Timestamp of when the pair token was last updated.
    function _latestRoundData(
        address mainToken
    ) internal view returns (int256 answer, uint256 updatedAt) {
        V3PoolConfig memory v3PoolConfig = assetToV3PoolConfig[mainToken];
        address pairToken = v3PoolConfig.pairToken;
        IAggregatorV3Interface pairTokenUsdAggregator = VALIO_REGISTRY
            .chainlinkV3USDAggregators(pairToken);

        uint mainTokenUnit = 10 ** IERC20Metadata(mainToken).decimals();

        uint pairTokenUnit = 10 ** IERC20Metadata(pairToken).decimals();

        (int24 tick, ) = OracleLibrary.consult(
            address(v3PoolConfig.pool),
            SECONDS_AGO
        );

        uint256 quoteAmount = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(mainTokenUnit),
            mainToken,
            pairToken
        );

        int256 pairUsdPrice;
        (, pairUsdPrice, , updatedAt, ) = pairTokenUsdAggregator
            .latestRoundData();

        answer = (pairUsdPrice * int256(quoteAmount)) / int256(pairTokenUnit);

        return (answer, updatedAt);
    }
}