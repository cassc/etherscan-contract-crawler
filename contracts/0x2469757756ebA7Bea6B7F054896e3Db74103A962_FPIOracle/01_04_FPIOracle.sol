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
// =========================== FPIOracle ==============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/ICPITrackerOracle.sol";

/// @title FPIOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  A contract to return the price of FPI in USD
contract FPIOracle is AggregatorV3Interface {
    using SafeCast for uint256;

    /// @notice the address of the CPI tracker oracle
    ICPITrackerOracle public immutable CPI_TRACKER_ORACLE;

    /// @notice the decimals of precision of the CPI tracket Oracle
    uint8 public immutable CPI_TRACKER_ORACLE_DECIMALS;

    /// @notice The decimals of precision for the price data given by this oracle
    uint8 public immutable decimals;

    /// @notice The ```constructor``` function
    /// @param _cpiTrackerOracleAddress The address of the CPI tracker oracle
    /// @param _cpiTrackerOracleDecimals The decimals of the CPI tracker oracle
    constructor(address _cpiTrackerOracleAddress, uint8 _cpiTrackerOracleDecimals) {
        CPI_TRACKER_ORACLE = ICPITrackerOracle(_cpiTrackerOracleAddress);
        CPI_TRACKER_ORACLE_DECIMALS = _cpiTrackerOracleDecimals;
        decimals = _cpiTrackerOracleDecimals;
    }

    /// @notice The ```description``` function returns the description of the oracle in the format used by Chainlink (Item / Units)
    /// @return memory The description of the oracle
    function description() external pure returns (string memory) {
        return "FPI / USD";
    }

    /// @notice The version of the oracle
    function version() external pure returns (uint256) {
        return 2;
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        revert("No Implementation for getRoundData");
    }

    /// @notice The ```latestRoundData``` function returns the latest data for chainlink feeds
    /// @dev Uses block.number for round info and block.timestamp for updatedAt/startedAt
    /// @return roundId The round in which the answer was computed
    /// @return answer The price
    /// @return startedAt The timestamp when the round started
    /// @return updatedAt The timestamp when the round was updated
    /// @return answeredInRound The round in which the answer was computed
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = uint80(block.number);
        startedAt = block.timestamp;
        updatedAt = startedAt;
        answeredInRound = roundId;

        answer = CPI_TRACKER_ORACLE.currPegPrice().toInt256();
    }
}