// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma abicoder v2;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IPriceConsumer } from "../interfaces/IPriceConsumer.sol";

interface IFeedRegistryInterface {
    function decimals(address base, address quote) external view returns (uint8);

    function getFeed(address base, address quote) external view returns (AggregatorV3Interface aggregator);

    function latestRoundData(address base, address quote)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract ChainlinkPriceConsumer is IPriceConsumer, AccessControlEnumerable {
    // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
    address private constant _USD = address(840);
    address private _registry;

    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");

    mapping(address => uint256) private _tokenPrice;
    mapping(address => uint256) private _tokenTimestamp;
    mapping(address => address) public feed;

    /**
     * Network: Ethereum Mainnet
     * Feed Registry: 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
     */
    constructor(address registry) {
        _registry = registry;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function fetchPriceInUSD(address token, uint256 minTimestamp) external override onlyRole(ORACLE_MANAGER_ROLE) {
        if (_tokenTimestamp[token] >= minTimestamp) return;
        int256 price = 0;
        uint256 timeStamp = 0;
        // If we don't have a feed available for a given token, try the registry if available
        if (feed[token] != address(0)) {
            (, price, , timeStamp, ) = AggregatorV3Interface(feed[token]).latestRoundData();
        } else if (_registry != address(0)) {
            (, price, , timeStamp, ) = IFeedRegistryInterface(_registry).latestRoundData(token, _USD);
        } else return;

        if (timeStamp < minTimestamp) return;
        _tokenPrice[token] = price >= 0 ? uint256(price) : 0;
        _tokenTimestamp[token] = timeStamp;
    }

    function getPriceInUSD(address token)
        external
        view
        override
        returns (
            uint256 price,
            uint256 decimals,
            uint256 timestamp
        )
    {
        price = _tokenPrice[token];
        timestamp = _tokenTimestamp[token];
        address tokenFeed = feed[token];
        if (tokenFeed == address(0) && _registry != address(0)) {
            try IFeedRegistryInterface(_registry).getFeed(token, _USD) returns (AggregatorV3Interface aggregator) {
                tokenFeed = address(aggregator);
            } catch {}
        }
        if (tokenFeed == address(0)) {
            return (price, decimals, timestamp);
        }
        decimals = AggregatorV3Interface(tokenFeed).decimals();
        try AggregatorV3Interface(tokenFeed).latestRoundData() returns (uint80, int256 answer, uint256, uint256 lastTimestamp, uint80) {
            price = uint256(answer);
            timestamp = lastTimestamp;
        } catch {}
    }

    function updateFeed(address _token, address _feed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feed[_token] = _feed;
    }

    function updateRegistry(address registry) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _registry = registry;
    }
}