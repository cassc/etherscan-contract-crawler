// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================ EthUsdChainlinkOracleWithMaxDelay =================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import {
    IEthUsdChainlinkOracleWithMaxDelay
} from "interfaces/oracles/abstracts/IEthUsdChainlinkOracleWithMaxDelay.sol";

struct ConstructorParams {
    address ethUsdChainlinkFeedAddress;
    uint256 maxEthUsdOracleDelay;
}

/// @title EthUsdChainlinkOracleWithMaxDelay
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract oracle for getting eth/usd prices from Chainlink
abstract contract EthUsdChainlinkOracleWithMaxDelay is ERC165Storage, IEthUsdChainlinkOracleWithMaxDelay {
    /// @notice Chainlink aggregator
    address public immutable ETH_USD_CHAINLINK_FEED_ADDRESS;

    /// @notice Decimals of ETH/USD chainlink feed
    uint8 public immutable ETH_USD_CHAINLINK_FEED_DECIMALS;

    /// @notice Precision of ETH/USD chainlink feed
    uint256 public immutable ETH_USD_CHAINLINK_FEED_PRECISION;

    /// @notice Maximum delay of Chainlink data, after which it is considered stale
    uint256 public maximumEthUsdOracleDelay;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IEthUsdChainlinkOracleWithMaxDelay).interfaceId });

        ETH_USD_CHAINLINK_FEED_ADDRESS = _params.ethUsdChainlinkFeedAddress;
        ETH_USD_CHAINLINK_FEED_DECIMALS = AggregatorV3Interface(ETH_USD_CHAINLINK_FEED_ADDRESS).decimals();
        ETH_USD_CHAINLINK_FEED_PRECISION = 10 ** uint256(ETH_USD_CHAINLINK_FEED_DECIMALS);
        maximumEthUsdOracleDelay = _params.maxEthUsdOracleDelay;
    }

    /// @notice The ```_setMaximumEthUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) internal {
        emit SetMaximumEthUsdOracleDelay({
            oldMaxOracleDelay: maximumEthUsdOracleDelay,
            newMaxOracleDelay: _newMaxOracleDelay
        });
        maximumEthUsdOracleDelay = _newMaxOracleDelay;
    }

    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external virtual;

    /// @notice The ```_getEthUsdChainlinkPrice``` function is called to get the eth/usd price from Chainlink
    /// @dev If data is stale or negative, set bad data to true and return
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerEth The eth/usd price
    function _getEthUsdChainlinkPrice()
        internal
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth)
    {
        (, int256 _answer, , uint256 _ethUsdChainlinkUpdatedAt, ) = AggregatorV3Interface(
            ETH_USD_CHAINLINK_FEED_ADDRESS
        ).latestRoundData();

        // If data is stale or negative, set bad data to true and return
        _isBadData = _answer <= 0 || ((block.timestamp - _ethUsdChainlinkUpdatedAt) > maximumEthUsdOracleDelay);
        _updatedAt = _ethUsdChainlinkUpdatedAt;
        _usdPerEth = uint256(_answer);
    }

    /// @notice The ```getEthUsdChainlinkPrice``` function is called to get the eth/usd price from Chainlink
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerEth The eth/usd price
    function getEthUsdChainlinkPrice()
        external
        view
        virtual
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth)
    {
        (_isBadData, _updatedAt, _usdPerEth) = _getEthUsdChainlinkPrice();
    }
}