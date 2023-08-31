// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapFactoryErrors} from "./IButtonswapFactoryErrors.sol";
import {IButtonswapFactoryEvents} from "./IButtonswapFactoryEvents.sol";

interface IButtonswapFactory is IButtonswapFactoryErrors, IButtonswapFactoryEvents {
    /**
     * @notice Returns the current address for `feeTo`.
     * The owner of this address receives the protocol fee as it is collected over time.
     * @return _feeTo The `feeTo` address
     */
    function feeTo() external view returns (address _feeTo);

    /**
     * @notice Returns the current address for `feeToSetter`.
     * The owner of this address has the power to update both `feeToSetter` and `feeTo`.
     * @return _feeToSetter The `feeToSetter` address
     */
    function feeToSetter() external view returns (address _feeToSetter);

    /**
     * @notice The name of the ERC20 liquidity token.
     * @return _tokenName The `tokenName`
     */
    function tokenName() external view returns (string memory _tokenName);

    /**
     * @notice The symbol of the ERC20 liquidity token.
     * @return _tokenSymbol The `tokenSymbol`
     */
    function tokenSymbol() external view returns (string memory _tokenSymbol);

    /**
     * @notice Returns the current state of restricted creation.
     * If true, then no new pairs, only feeToSetter can create new pairs
     * @return _isCreationRestricted The `isCreationRestricted` state
     */
    function isCreationRestricted() external view returns (bool _isCreationRestricted);

    /**
     * @notice Returns the current address for `isCreationRestrictedSetter`.
     * The owner of this address has the power to update both `isCreationRestrictedSetter` and `isCreationRestricted`.
     * @return _isCreationRestrictedSetter The `isCreationRestrictedSetter` address
     */
    function isCreationRestrictedSetter() external view returns (address _isCreationRestrictedSetter);

    /**
     * @notice Get the (unique) Pair address created for the given combination of `tokenA` and `tokenB`.
     * If the Pair does not exist then zero address is returned.
     * @param tokenA The first unsorted token
     * @param tokenB The second unsorted token
     * @return pair The address of the Pair instance
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Get the Pair address at the given `index`, ordered chronologically.
     * @param index The index to query
     * @return pair The address of the Pair created at the given `index`
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @notice Get the current total number of Pairs created
     * @return count The total number of Pairs created
     */
    function allPairsLength() external view returns (uint256 count);

    /**
     * @notice Creates a new {ButtonswapPair} instance for the given unsorted tokens `tokenA` and `tokenB`.
     * @dev The tokens are sorted later, but can be provided to this method in either order.
     * @param tokenA The first unsorted token address
     * @param tokenB The second unsorted token address
     * @return pair The address of the new {ButtonswapPair} instance
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Updates the address that receives the protocol fee.
     * This can only be called by the `feeToSetter` address.
     * @param _feeTo The new address
     */
    function setFeeTo(address _feeTo) external;

    /**
     * @notice Updates the address that has the power to set the `feeToSetter` and `feeTo` addresses.
     * This can only be called by the `feeToSetter` address.
     * @param _feeToSetter The new address
     */
    function setFeeToSetter(address _feeToSetter) external;

    /**
     * @notice Updates the state of restricted creation.
     * This can only be called by the `feeToSetter` address.
     * @param _isCreationRestricted The new state
     */
    function setIsCreationRestricted(bool _isCreationRestricted) external;

    /**
     * @notice Updates the address that has the power to set the `isCreationRestrictedSetter` and `isCreationRestricted`.
     * This can only be called by the `isCreationRestrictedSetter` address.
     * @param _isCreationRestrictedSetter The new address
     */
    function setIsCreationRestrictedSetter(address _isCreationRestrictedSetter) external;

    /**
     * @notice Returns the current address for `isPausedSetter`.
     * The owner of this address has the power to update both `isPausedSetter` and call `setIsPaused`.
     * @return _isPausedSetter The `isPausedSetter` address
     */
    function isPausedSetter() external view returns (address _isPausedSetter);

    /**
     * @notice Updates the address that has the power to set the `isPausedSetter` and call `setIsPaused`.
     * This can only be called by the `isPausedSetter` address.
     * @param _isPausedSetter The new address
     */
    function setIsPausedSetter(address _isPausedSetter) external;

    /**
     * @notice Updates the pause state of given Pairs.
     * This can only be called by the `feeToSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param isPausedNew The new pause state
     */
    function setIsPaused(address[] calldata pairs, bool isPausedNew) external;

    /**
     * @notice Returns the current address for `paramSetter`.
     * The owner of this address has the power to update `paramSetter`, default parameters, and current parameters on existing pairs
     * @return _paramSetter The `paramSetter` address
     */
    function paramSetter() external view returns (address _paramSetter);

    /**
     * @notice Updates the address that has the power to set the `paramSetter` and update the default params.
     * This can only be called by the `paramSetter` address.
     * @param _paramSetter The new address
     */
    function setParamSetter(address _paramSetter) external;

    /**
     * @notice Returns the default value of `movingAverageWindow` used for new pairs.
     * @return _defaultMovingAverageWindow The `defaultMovingAverageWindow` value
     */
    function defaultMovingAverageWindow() external view returns (uint32 _defaultMovingAverageWindow);

    /**
     * @notice Returns the default value of `maxVolatilityBps` used for new pairs.
     * @return _defaultMaxVolatilityBps The `defaultMaxVolatilityBps` value
     */
    function defaultMaxVolatilityBps() external view returns (uint16 _defaultMaxVolatilityBps);

    /**
     * @notice Returns the default value of `minTimelockDuration` used for new pairs.
     * @return _defaultMinTimelockDuration The `defaultMinTimelockDuration` value
     */
    function defaultMinTimelockDuration() external view returns (uint32 _defaultMinTimelockDuration);

    /**
     * @notice Returns the default value of `maxTimelockDuration` used for new pairs.
     * @return _defaultMaxTimelockDuration The `defaultMaxTimelockDuration` value
     */
    function defaultMaxTimelockDuration() external view returns (uint32 _defaultMaxTimelockDuration);

    /**
     * @notice Returns the default value of `maxSwappableReservoirLimitBps` used for new pairs.
     * @return _defaultMaxSwappableReservoirLimitBps The `defaultMaxSwappableReservoirLimitBps` value
     */
    function defaultMaxSwappableReservoirLimitBps()
        external
        view
        returns (uint16 _defaultMaxSwappableReservoirLimitBps);

    /**
     * @notice Returns the default value of `swappableReservoirGrowthWindow` used for new pairs.
     * @return _defaultSwappableReservoirGrowthWindow The `defaultSwappableReservoirGrowthWindow` value
     */
    function defaultSwappableReservoirGrowthWindow()
        external
        view
        returns (uint32 _defaultSwappableReservoirGrowthWindow);

    /**
     * @notice Updates the default parameters used for new pairs.
     * This can only be called by the `paramSetter` address.
     * @param newDefaultMovingAverageWindow The new defaultMovingAverageWindow
     * @param newDefaultMaxVolatilityBps The new defaultMaxVolatilityBps
     * @param newDefaultMinTimelockDuration The new defaultMinTimelockDuration
     * @param newDefaultMaxTimelockDuration The new defaultMaxTimelockDuration
     * @param newDefaultMaxSwappableReservoirLimitBps The new defaultMaxSwappableReservoirLimitBps
     * @param newDefaultSwappableReservoirGrowthWindow The new defaultSwappableReservoirGrowthWindow
     */
    function setDefaultParameters(
        uint32 newDefaultMovingAverageWindow,
        uint16 newDefaultMaxVolatilityBps,
        uint32 newDefaultMinTimelockDuration,
        uint32 newDefaultMaxTimelockDuration,
        uint16 newDefaultMaxSwappableReservoirLimitBps,
        uint32 newDefaultSwappableReservoirGrowthWindow
    ) external;

    /**
     * @notice Updates the `movingAverageWindow` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMovingAverageWindow The new `movingAverageWindow` value
     */
    function setMovingAverageWindow(address[] calldata pairs, uint32 newMovingAverageWindow) external;

    /**
     * @notice Updates the `maxVolatilityBps` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxVolatilityBps The new `maxVolatilityBps` value
     */
    function setMaxVolatilityBps(address[] calldata pairs, uint16 newMaxVolatilityBps) external;

    /**
     * @notice Updates the `minTimelockDuration` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMinTimelockDuration The new `minTimelockDuration` value
     */
    function setMinTimelockDuration(address[] calldata pairs, uint32 newMinTimelockDuration) external;

    /**
     * @notice Updates the `maxTimelockDuration` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxTimelockDuration The new `maxTimelockDuration` value
     */
    function setMaxTimelockDuration(address[] calldata pairs, uint32 newMaxTimelockDuration) external;

    /**
     * @notice Updates the `maxSwappableReservoirLimitBps` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxSwappableReservoirLimitBps The new `maxSwappableReservoirLimitBps` value
     */
    function setMaxSwappableReservoirLimitBps(address[] calldata pairs, uint16 newMaxSwappableReservoirLimitBps)
        external;

    /**
     * @notice Updates the `swappableReservoirGrowthWindow` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newSwappableReservoirGrowthWindow The new `swappableReservoirGrowthWindow` value
     */
    function setSwappableReservoirGrowthWindow(address[] calldata pairs, uint32 newSwappableReservoirGrowthWindow)
        external;

    /**
     * @notice Returns the last token pair created and the parameters used.
     * @return token0 The first token address
     * @return token1 The second token address
     * @return movingAverageWindow The moving average window
     * @return maxVolatilityBps The max volatility bps
     * @return minTimelockDuration The minimum time lock duration
     * @return maxTimelockDuration The maximum time lock duration
     * @return maxSwappableReservoirLimitBps The max swappable reservoir limit bps
     * @return swappableReservoirGrowthWindow The swappable reservoir growth window
     */
    function lastCreatedTokensAndParameters()
        external
        returns (
            address token0,
            address token1,
            uint32 movingAverageWindow,
            uint16 maxVolatilityBps,
            uint32 minTimelockDuration,
            uint32 maxTimelockDuration,
            uint16 maxSwappableReservoirLimitBps,
            uint32 swappableReservoirGrowthWindow
        );
}