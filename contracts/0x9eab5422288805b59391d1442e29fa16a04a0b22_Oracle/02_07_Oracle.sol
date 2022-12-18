// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "chainlink/interfaces/FeedRegistryInterface.sol";
import {Denominations} from "chainlink/Denominations.sol";
import "../../interfaces/IOracle.sol";

/**
 * @title   - Chainlink Feed Registry Wrapper
 * @notice  - simple contract that wraps Chainlink's Feed Registry to get asset prices for any tokens without needing to know the specific oracle address
 *          - only makes request for USD prices and returns results in standard 8 decimals for Chainlink USD feeds
 */
contract Oracle is IOracle {
    /// @notice registry - Chainlink Feed Registry with aggregated prices across
    FeedRegistryInterface internal registry;
    /// @notice NULL_PRICE - null price when asset price feed is deemed invalid
    int256 public constant NULL_PRICE = 0;
    /// @notice PRICE_DECIMALS - the normalized amount of decimals for returned prices in USD
    uint8 public constant PRICE_DECIMALS = 8;
    /// @notice MAX_PRICE_LATENCY - amount of time between oracle responses until an asset is determined toxiz
    /// Assumes Chainlink updates price minimum of once every 24hrs and 1 hour buffer for network issues
    uint256 public constant MAX_PRICE_LATENCY = 25 hours;

    event StalePrice(address indexed token, uint256 answerTimestamp);
    event NullPrice(address indexed token);
    event NoDecimalData(address indexed token, bytes errData);
    event NoRoundData(address indexed token, bytes errData);

    constructor(address _registry) {
        registry = FeedRegistryInterface(_registry);
    }

    /**
     * @param token - ERC20 token to get USD price for
     * @return price - the latest price in USD to 8 decimals
     */
    function getLatestAnswer(address token) external returns (int256) {
        try registry.latestRoundData(token, Denominations.USD) returns (
            uint80 /* uint80 roundID */,
            int256 _price,
            uint256 /* uint256 roundStartTime */,
            uint256 answerTimestamp /* uint80 answeredInRound */,
            uint80
        ) {
            // no price for asset if price is stale. Asset is toxic
            if (answerTimestamp == 0 || block.timestamp - answerTimestamp > MAX_PRICE_LATENCY) {
                emit StalePrice(token, answerTimestamp);
                return NULL_PRICE;
            }
            if (_price <= NULL_PRICE) {
                emit NullPrice(token);
                return NULL_PRICE;
            }

            try registry.decimals(token, Denominations.USD) returns (uint8 decimals) {
                // if already at target decimals then return price
                if (decimals == PRICE_DECIMALS) return _price;
                // transform decimals to target value. disregard rounding errors
                return
                    decimals < PRICE_DECIMALS
                        ? _price * int256(10 ** (PRICE_DECIMALS - decimals))
                        : _price / int256(10 ** (decimals - PRICE_DECIMALS));
            } catch (bytes memory msg_) {
                emit NoDecimalData(token, msg_);
                return NULL_PRICE;
            }
            // another try catch for decimals call
        } catch (bytes memory msg_) {
            emit NoRoundData(token, msg_);
            return NULL_PRICE;
        }
    }
}