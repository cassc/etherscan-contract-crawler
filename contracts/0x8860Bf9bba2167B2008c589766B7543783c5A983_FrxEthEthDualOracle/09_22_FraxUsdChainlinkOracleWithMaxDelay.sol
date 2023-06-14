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
// ================ FraxUsdChainlinkOracleWithMaxDelay =================
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
    IFraxUsdChainlinkOracleWithMaxDelay
} from "interfaces/oracles/abstracts/IFraxUsdChainlinkOracleWithMaxDelay.sol";

struct ConstructorParams {
    address fraxUsdChainlinkFeedAddress;
    uint256 fraxUsdMaximumOracleDelay;
}

/// @title FraxUsdChainlinkOracleWithMaxDelay
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract oracle for getting frax/usd prices from Chainlink
abstract contract FraxUsdChainlinkOracleWithMaxDelay is ERC165Storage, IFraxUsdChainlinkOracleWithMaxDelay {
    /// @notice Chainlink aggregator
    address public immutable FRAX_USD_CHAINLINK_FEED_ADDRESS;

    /// @notice Decimals of FRAX/USD chainlink feed
    uint8 public immutable FRAX_USD_CHAINLINK_FEED_DECIMALS;

    /// @notice Precision of FRAX/USD chainlink feed
    uint256 public immutable FRAX_USD_CHAINLINK_FEED_PRECISION;

    /// @notice Maximum delay of Chainlink data, after which it is considered stale
    uint256 public maximumFraxUsdOracleDelay;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IFraxUsdChainlinkOracleWithMaxDelay).interfaceId });

        FRAX_USD_CHAINLINK_FEED_ADDRESS = _params.fraxUsdChainlinkFeedAddress;
        FRAX_USD_CHAINLINK_FEED_DECIMALS = AggregatorV3Interface(FRAX_USD_CHAINLINK_FEED_ADDRESS).decimals();
        FRAX_USD_CHAINLINK_FEED_PRECISION = 10 ** uint256(FRAX_USD_CHAINLINK_FEED_DECIMALS);
        maximumFraxUsdOracleDelay = _params.fraxUsdMaximumOracleDelay;
    }

    /// @notice The ```_setMaximumFraxUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) internal {
        emit SetMaximumFraxUsdOracleDelay({
            oldMaxOracleDelay: maximumFraxUsdOracleDelay,
            newMaxOracleDelay: _newMaxOracleDelay
        });
        maximumFraxUsdOracleDelay = _newMaxOracleDelay;
    }

    function setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) external virtual;

    /// @notice The ```_getFraxUsdChainlinkPrice``` function is called to get the frax/usd price from Chainlink
    /// @dev If data is stale or negative, set bad data to true and return
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerFrax The frax/usd price
    function _getFraxUsdChainlinkPrice()
        internal
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerFrax)
    {
        (, int256 _answer, , uint256 _fraxUsdChainlinkUpdatedAt, ) = AggregatorV3Interface(
            FRAX_USD_CHAINLINK_FEED_ADDRESS
        ).latestRoundData();

        // If data is stale or negative, set bad data to true and return
        _isBadData = _answer <= 0 || ((block.timestamp - _fraxUsdChainlinkUpdatedAt) > maximumFraxUsdOracleDelay);
        _updatedAt = _fraxUsdChainlinkUpdatedAt;
        _usdPerFrax = uint256(_answer);
    }

    /// @notice The ```getFraxUsdChainlinkPrice``` function is called to get the frax/usd price from Chainlink
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerFrax The frax/usd price
    function getFraxUsdChainlinkPrice()
        external
        view
        virtual
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerFrax)
    {
        (_isBadData, _updatedAt, _usdPerFrax) = _getFraxUsdChainlinkPrice();
    }
}