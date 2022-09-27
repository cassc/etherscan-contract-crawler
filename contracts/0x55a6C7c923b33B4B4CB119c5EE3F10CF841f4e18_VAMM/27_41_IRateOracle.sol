// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../../utils/CustomErrors.sol";
import "../IERC20Minimal.sol";

/// @dev The RateOracle is used for two purposes on the Voltz Protocol
/// @dev Settlement: in order to be able to settle IRS positions after the termEndTimestamp of a given AMM
/// @dev Margin Engine Computations: getApyFromTo is used by the MarginEngine
/// @dev It is necessary to produce margin requirements for Trader and Liquidity Providers
interface IRateOracle is CustomErrors {

    // events
    event MinSecondsSinceLastUpdate(uint256 _minSecondsSinceLastUpdate);
    event OracleBufferUpdate(
        uint256 blockTimestampScaled,
        address source,
        uint16 index,
        uint32 blockTimestamp,
        uint256 observedValue,
        uint16 cardinality,
        uint16 cardinalityNext
    );

    /// @notice Emitted by the rate oracle for increases to the number of observations that can be stored
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event RateCardinalityNext(
        uint16 observationCardinalityNextNew
    );

    // view functions

    /// @notice Gets minimum number of seconds that need to pass since the last update to the rates array
    /// @dev This is a throttling mechanic that needs to ensure we don't run out of space in the rates array
    /// @dev The maximum size of the rates array is 65535 entries
    // AB: as long as this doesn't affect the termEndTimestamp rateValue too much
    // AB: can have a different minSecondsSinceLastUpdate close to termEndTimestamp to have more granularity for settlement purposes
    /// @return minSecondsSinceLastUpdate in seconds
    function minSecondsSinceLastUpdate() external view returns (uint256);

    /// @notice Gets the address of the underlying token of the RateOracle
    /// @dev may be unset (`address(0)`) if the underlying is ETH
    /// @return underlying The address of the underlying token
    function underlying() external view returns (IERC20Minimal);

    /// @notice Gets the variable factor between termStartTimestamp and termEndTimestamp
    /// @return result The variable factor
    /// @dev If the current block timestamp is beyond the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp, termEndTimestamp). Term end timestamps are cached for quick retrieval later.
    /// @dev If the current block timestamp is before the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp,Time.blockTimestampScaled());
    /// @dev if queried before maturity then returns the rate of return between pool initiation and current timestamp (in wad)
    /// @dev if queried after maturity then returns the rate of return between pool initiation and maturity timestamp (in wad)
    function variableFactor(uint256 termStartTimestamp, uint256 termEndTimestamp) external returns(uint256 result);

    /// @notice Gets the variable factor between termStartTimestamp and termEndTimestamp
    /// @return result The variable factor
    /// @dev If the current block timestamp is beyond the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp, termEndTimestamp). No caching takes place.
    /// @dev If the current block timestamp is before the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp,Time.blockTimestampScaled());
    function variableFactorNoCache(uint256 termStartTimestamp, uint256 termEndTimestamp) external view returns(uint256 result);
    
    /// @notice Calculates the observed interest returned by the underlying in a given period
    /// @dev Reverts if we have no data point for `_from`
    /// @param _from The timestamp of the start of the period, in seconds
    /// @return The "floating rate" expressed in Wad, e.g. 4% is encoded as 0.04*10**18 = 4*10**16
    function getRateFrom(uint256 _from)
        external
        view
        returns (uint256);

    /// @notice Calculates the observed interest returned by the underlying in a given period
    /// @dev Reverts if we have no data point for either timestamp
    /// @param _from The timestamp of the start of the period, in seconds
    /// @param _to The timestamp of the end of the period, in seconds
    /// @return The "floating rate" expressed in Wad, e.g. 4% is encoded as 0.04*10**18 = 4*10**16
    function getRateFromTo(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    /// @notice Calculates the observed APY returned by the rate oracle between the given timestamp and the current time
    /// @param from The timestamp of the start of the period, in seconds
    /// @dev Reverts if we have no data point for `from`
    /// @return apyFromTo The "floating rate" expressed in Wad, e.g. 4% is encoded as 0.04*10**18 = 4*10**16
    function getApyFrom(uint256 from)
        external
        view
        returns (uint256 apyFromTo);

    /// @notice Calculates the observed APY returned by the rate oracle in a given period
    /// @param from The timestamp of the start of the period, in seconds
    /// @param to The timestamp of the end of the period, in seconds
    /// @dev Reverts if we have no data point for either timestamp
    /// @return apyFromTo The "floating rate" expressed in Wad, e.g. 4% is encoded as 0.04*10**18 = 4*10**16
    function getApyFromTo(uint256 from, uint256 to)
        external
        view
        returns (uint256 apyFromTo);

    // non-view functions

    /// @notice Sets minSecondsSinceLastUpdate: The minimum number of seconds that need to pass since the last update to the rates array
    /// @dev Can only be set by the Factory Owner
    function setMinSecondsSinceLastUpdate(uint256 _minSecondsSinceLastUpdate) external;

    /// @notice Increase the maximum number of rates observations that this RateOracle will store
    /// @dev This method is no-op if the RateOracle already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param rateCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 rateCardinalityNext) external;

    /// @notice Writes a rate observation to the rates array given the current rate cardinality, rate index and rate cardinality next
    /// Write oracle entry is called whenever a new position is minted via the vamm or when a swap is initiated via the vamm
    /// That way the gas costs of Rate Oracle updates can be distributed across organic interactions with the protocol
    function writeOracleEntry() external;

    /// @notice unique ID of the underlying yield bearing protocol (e.g. Aave v2 has id 1)
    /// @return yieldBearingProtocolID unique id of the underlying yield bearing protocol
    function UNDERLYING_YIELD_BEARING_PROTOCOL_ID() external view returns(uint8 yieldBearingProtocolID);

    /// @notice returns the last change in rate and time
    /// Gets the last two observations and returns the change in rate and time.
    /// This can help us to extrapolate an estiamte of the current rate from recent known rates. 
    function getLastRateSlope()
        external
        view
        returns (uint256 rateChange, uint32 timeChange);

    /// @notice Get the current "rate" in Ray at the current timestamp.
    /// This might be a direct reading if real-time readings are available, or it might be an extrapolation from recent known rates.
    /// The source and expected values of "rate" may differ by rate oracle type. All that
    /// matters is that we can divide one "rate" by another "rate" to get the factor of growth between the two timestamps.
    /// For example if we have rates of { (t=0, rate=5), (t=100, rate=5.5) }, we can divide 5.5 by 5 to get a growth factor
    /// of 1.1, suggesting that 10% growth in capital was experienced between timesamp 0 and timestamp 100.
    /// @dev For convenience, the rate is normalised to Ray for storage, so that we can perform consistent math across all rates.
    /// @dev This function should revert if a valid rate cannot be discerned
    /// @return currentRate the rate in Ray (decimal scaled up by 10^27 for storage in a uint256)
    function getCurrentRateInRay()
        external
        view
        returns (uint256 currentRate);

    /// @notice returns the last change in block number and timestamp 
    /// Some implementations may use this data to estimate timestamps for recent rate readings, if we only know the block number
    function getBlockSlope()
        external
        view
        returns (uint256 blockChange, uint32 timeChange);
}