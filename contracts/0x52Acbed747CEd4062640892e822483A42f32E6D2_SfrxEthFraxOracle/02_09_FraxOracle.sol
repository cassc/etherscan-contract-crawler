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
// ============================ FraxOracle ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Jon Walch: https://github.com/jonwalch

// Contributors
// Dennis: https://github.com/denett

// Reviewers
// Drake Evans: https://github.com/DrakeEvans

// ====================================================================
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { ITimelock2Step } from "frax-std/access-control/v1/interfaces/ITimelock2Step.sol";
import { IPriceSourceReceiver } from "../interfaces/IPriceSourceReceiver.sol";

struct ConstructorParams {
    // = Timelock2Step
    address timelockAddress;
    // = FraxOracle
    address baseErc20;
    address quoteErc20;
    address priceSource;
    uint256 maximumDeviation;
    uint256 maximumOracleDelay;
}

/// @title FraxOracle
/// @author Jon Walch (Frax Finance) https://github.com/jonwalch
/// @notice Drop in replacement for a chainlink oracle, also supports Fraxlend style high and low prices
abstract contract FraxOracle is AggregatorV3Interface, IPriceSourceReceiver, ERC165Storage, Timelock2Step {
    /// @notice Maximum deviation of price source data between low and high, beyond which it is considered bad data
    uint256 public maximumDeviation;

    /// @notice Maximum delay of price source data, after which it is considered stale
    uint256 public maximumOracleDelay;

    /// @notice The address of the Erc20 base token contract
    address public immutable BASE_TOKEN;

    /// @notice The address of the Erc20 quote token contract
    address public immutable QUOTE_TOKEN;

    /// @notice Contract that posts price updates through addRoundData()
    address public priceSource;

    /// @notice Last round ID where isBadData is false and price is within maximum deviation
    uint80 public lastCorrectRoundId;

    /// @notice Array of round data
    Round[] public rounds;

    /// @notice Packed Round data struct
    struct Round {
        uint104 priceLow;
        uint104 priceHigh;
        uint40 timestamp;
        bool isBadData;
    }

    constructor(ConstructorParams memory params) Timelock2Step() {
        _setTimelock({ _newTimelock: params.timelockAddress });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });
        _registerInterface({ interfaceId: type(AggregatorV3Interface).interfaceId });
        _registerInterface({ interfaceId: type(IPriceSourceReceiver).interfaceId });

        BASE_TOKEN = params.baseErc20;
        QUOTE_TOKEN = params.quoteErc20;

        _setMaximumDeviation(params.maximumDeviation);
        _setMaximumOracleDelay(params.maximumOracleDelay);
        _setPriceSource(params.priceSource);
    }

    /// @notice The ```SetMaximumOracleDelay``` event is emitted when the max oracle delay is set
    /// @param oldMaxOracleDelay The old max oracle delay
    /// @param newMaxOracleDelay The new max oracle delay
    event SetMaximumOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    /// @notice The ```SetPriceSource``` event is emitted when the price source is set
    /// @param oldPriceSource The old price source address
    /// @param newPriceSource The new price source address
    event SetPriceSource(address oldPriceSource, address newPriceSource);

    /// @notice The ```SetMaximumDeviation``` event is emitted when the max oracle delay is set
    /// @param oldMaxDeviation The old max oracle delay
    /// @param newMaxDeviation The new max oracle delay
    event SetMaximumDeviation(uint256 oldMaxDeviation, uint256 newMaxDeviation);

    /// @notice The ```_setMaximumOracleDelay``` function sets the max oracle delay to determine if data is stale
    /// @param newMaxOracleDelay The new max oracle delay
    function _setMaximumOracleDelay(uint256 newMaxOracleDelay) internal {
        uint256 maxOracleDelay = maximumOracleDelay;
        if (maxOracleDelay == newMaxOracleDelay) revert SameMaximumOracleDelay();
        emit SetMaximumOracleDelay({ oldMaxOracleDelay: maxOracleDelay, newMaxOracleDelay: newMaxOracleDelay });
        maximumOracleDelay = newMaxOracleDelay;
    }

    /// @notice The ```_setPriceSource``` function sets the price source
    /// @param newPriceSource The new price source
    function _setPriceSource(address newPriceSource) internal {
        address _priceSource = priceSource;
        if (_priceSource == newPriceSource) revert SamePriceSource();
        emit SetPriceSource({ oldPriceSource: _priceSource, newPriceSource: newPriceSource });
        priceSource = newPriceSource;
    }

    /// @notice The ```_setMaximumDeviation``` function sets the maximum deviation between low and high
    /// @param newMaximumDeviation The new maximum deviation
    function _setMaximumDeviation(uint256 newMaximumDeviation) internal {
        uint256 maxDeviation = maximumDeviation;
        if (newMaximumDeviation == maxDeviation) revert SameMaximumDeviation();
        emit SetMaximumDeviation({ oldMaxDeviation: maxDeviation, newMaxDeviation: newMaximumDeviation });
        maximumDeviation = newMaximumDeviation;
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param newMaxOracleDelay The new max oracle delay
    function setMaximumOracleDelay(uint256 newMaxOracleDelay) external {
        _requireTimelock();
        _setMaximumOracleDelay({ newMaxOracleDelay: newMaxOracleDelay });
    }

    /// @notice The ```setPriceSource``` function sets the price source
    /// @dev Requires msg.sender to be the timelock address
    /// @param newPriceSource The new price source address
    function setPriceSource(address newPriceSource) external {
        _requireTimelock();
        _setPriceSource({ newPriceSource: newPriceSource });
    }

    /// @notice The ```setMaximumDeviation``` function sets the max oracle delay to determine if data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param newMaxDeviation The new max oracle delay
    function setMaximumDeviation(uint256 newMaxDeviation) external {
        _requireTimelock();
        _setMaximumDeviation({ newMaximumDeviation: newMaxDeviation });
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    /// @notice The ```decimals``` function returns the number of decimals in the response.
    function decimals() external pure virtual override returns (uint8 _decimals) {
        _decimals = 18;
    }

    /// @notice The ```version``` function returns the version number for the AggregatorV3Interface.
    /// @dev Adheres to AggregatorV3Interface, which is different than typical semver
    function version() external view virtual returns (uint256 _version) {
        _version = 1;
    }

    // ====================================================================
    // Price Source Receiver
    // ====================================================================

    /// @notice The ```addRoundData``` adds new price data to be served later
    /// @dev Can only be called by the preconfigured price source
    /// @param isBadData Boolean representing if the data is bad from underlying chainlink oracles from FraxDualOracle's getPrices()
    /// @param priceLow The low price returned from a FraxDualOracle's getPrices()
    /// @param priceHigh The high price returned from a FraxDualOracle's getPrices()
    /// @param timestamp The timestamp that FraxDualOracle's getPrices() was called
    function addRoundData(bool isBadData, uint104 priceLow, uint104 priceHigh, uint40 timestamp) external {
        if (msg.sender != priceSource) revert OnlyPriceSource();
        if (timestamp > block.timestamp) revert CalledWithFutureTimestamp();

        uint256 roundsLength = rounds.length;
        if (roundsLength > 0 && timestamp <= rounds[roundsLength - 1].timestamp) {
            revert CalledWithTimestampBeforePreviousRound();
        }

        if (!isBadData && (((uint256(priceHigh) - priceLow) * 1e18) / priceHigh <= maximumDeviation)) {
            lastCorrectRoundId = uint80(roundsLength);
        }

        rounds.push(Round({ isBadData: isBadData, priceLow: priceLow, priceHigh: priceHigh, timestamp: timestamp }));
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    function _getPrices() internal view returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        uint256 roundsLength = rounds.length;
        if (roundsLength == 0) revert NoPriceData();
        Round memory round = rounds[roundsLength - 1];
        isBadData = round.isBadData || round.timestamp + maximumOracleDelay < block.timestamp;
        priceLow = round.priceLow;
        priceHigh = round.priceHigh;
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return isBadData is true when data is stale or otherwise bad
    /// @return priceLow is the lower of the two prices
    /// @return priceHigh is the higher of the two prices
    function getPrices() external view returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        (isBadData, priceLow, priceHigh) = _getPrices();
    }

    function _getRoundData(
        uint80 _roundId
    )
        internal
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        if (rounds.length <= _roundId) revert NoPriceData();

        Round memory round = rounds[_roundId];
        roundId = answeredInRound = _roundId;
        answer = int256((uint256(round.priceHigh) + round.priceLow) / 2);
        startedAt = updatedAt = round.timestamp;
    }

    /// @notice The ```getRoundData``` function returns price data
    /// @param _roundId The round ID
    /// @return roundId The round ID
    /// @return answer The data that this specific feed provides
    /// @return startedAt Timestamp of when the round started
    /// @return updatedAt Timestamp of when the round was updated
    /// @return answeredInRound The round ID in which the answer was computed
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = _getRoundData(_roundId);
    }

    /// @notice The ```latestRoundData``` function returns price data
    /// @dev Will only return the latest data that is not bad and within the maximum price deviation
    /// @return roundId The round ID
    /// @return answer The data that this specific feed provides
    /// @return startedAt Timestamp of when the round started
    /// @return updatedAt Timestamp of when the round was updated
    /// @return answeredInRound The round ID in which the answer was computed
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = _getRoundData(lastCorrectRoundId);
    }

    error CalledWithFutureTimestamp();
    error CalledWithTimestampBeforePreviousRound();
    error NoPriceData();
    error OnlyPriceSource();
    error SameMaximumDeviation();
    error SameMaximumOracleDelay();
    error SamePriceSource();
}