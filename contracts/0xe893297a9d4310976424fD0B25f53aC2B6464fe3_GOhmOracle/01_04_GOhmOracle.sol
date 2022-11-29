// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== GOhmOracle =============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// ====================================================================

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IGOhm.sol";

/// @title GOhmOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  A contract to combine the gOHM index and the OHM/ETH & ETH/USD Chainlink feeds to get the price of gOhm in USD
contract GOhmOracle is AggregatorV3Interface {
    using SafeCast for int256;
    using SafeCast for uint256;

    /// @notice The precision of the gOHM index
    uint256 public constant GOHM_INDEX_PRECISION = 1e9;

    /// @notice The contract where gOhm is accrued
    IGOhm public immutable GOHM;

    /// @notice The ohmV2-ETH chainlink oracle feed
    AggregatorV3Interface public immutable OHM_ETH_FEED;

    /// @notice The ETH-USD chainlink oracle feed precision
    uint256 public immutable OHM_ETH_PRECISION;

    /// @notice The ETH-USD chainlink oracle feed
    AggregatorV3Interface public immutable ETH_USD_FEED;

    /// @notice The ETH-USD chainlink oracle feed precision
    uint256 public immutable ETH_USD_PRECISION;

    /// @notice The decimals of precision for the price data given by this oracle
    uint8 public constant decimals = 18;

    /// @notice The chainlink version of this oracle
    uint256 public constant version = 4;

    /// @notice The ```constructor``` function
    /// @param _gOhm The address of the gOhm contract
    /// @param _ohmEthFeed The address of the Ohm Eth Chainlink feed
    /// @param _ethUsdFeed The address of the Eth Usd Chainlink feed
    constructor(address _gOhm, address _ohmEthFeed, address _ethUsdFeed) {
        GOHM = IGOhm(_gOhm);
        OHM_ETH_FEED = AggregatorV3Interface(_ohmEthFeed);
        ETH_USD_FEED = AggregatorV3Interface(_ethUsdFeed);
        OHM_ETH_PRECISION = 10**OHM_ETH_FEED.decimals();
        ETH_USD_PRECISION = 10**ETH_USD_FEED.decimals();
    }

    /// @notice The ```description``` function returns the description of the oracle in the format used by Chainlink
    /// @return memory The description of the oracle
    function description() external pure returns (string memory) {
        return "gOhmV2 / USD";
    }

    /// @notice The ```latestRoundData``` function returns the latest data for chainlink feeds
    /// @dev Uses metadata from the oldest of the two feeds
    /// @return roundId The round in which the answer was computed
    /// @return answer The price
    /// @return startedAt The timestamp when the round started
    /// @return updatedAt The timestamp when the round was updated
    /// @return answeredInRound The round in which the answer was computed
    function latestRoundData()
        public
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // Get Eth in USD terms
        (
            uint80 _roundIdEthUsd,
            int256 _answerEthUsd,
            uint256 _startedAtEthUsd,
            uint256 _updatedAtEthUsd,
            uint80 _answeredInRoundEthUsd
        ) = ETH_USD_FEED.latestRoundData();

        // Get Ohm in Eth terms
        (
            uint80 _roundIdOhmEth,
            int256 _answerOhmEth,
            uint256 _startedAtOhmEth,
            uint256 _updatedAtOhmEth,
            uint80 _answeredInRoundOhmEth
        ) = OHM_ETH_FEED.latestRoundData();

        // Use the metadata from the oldest of the two feeds
        if (_updatedAtEthUsd < _updatedAtOhmEth) {
            roundId = _roundIdEthUsd;
            startedAt = _startedAtEthUsd;
            updatedAt = _updatedAtEthUsd;
            answeredInRound = _answeredInRoundEthUsd;
        } else {
            roundId = _roundIdOhmEth;
            startedAt = _startedAtOhmEth;
            updatedAt = _updatedAtOhmEth;
            answeredInRound = _answeredInRoundOhmEth;
        }
        // GOHM.index() gives Ohm per gOhm i.e. (OHM / gOHM)
        // (ETH / OHM) * (USD / ETH) * (OHM / gOHM) = USD / gOhm
        answer = ((((_answerOhmEth.toUint256() * _answerEthUsd.toUint256() * 1e18) /
            (OHM_ETH_PRECISION * ETH_USD_PRECISION)) * GOHM.index()) / GOHM_INDEX_PRECISION).toInt256();
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        revert("No Implementation for getRoundData");
    }
}