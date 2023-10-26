// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IContractGenerator interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for generating and cloning token and option contract instances
 */
interface IContractGenerator {
    /**
     * @notice Create a new BULLET and SNIPER token pair for the specified option
     * @dev Generates a new token pair associated with the given option
     * @param optionId The ID of the option associated with the token pair
     * @param optionAddress The address of the option contract
     * @return bullet The address of the newly created BULLET token
     * @return sniper The address of the newly created SNIPER token
     */
    function createToken(uint256 optionId, address optionAddress) external returns (address bullet, address sniper);

    /**
     * @notice Clone existing Bullet and Sniper tokens for a new option contract
     * @dev Creates new token instances by cloning the provided Bullet and Sniper token sources
     * @param _optionAddress The address of the option contract associated with the new tokens
     * @param _bulletSource The address of the source Bullet token to clone
     * @param _sniperSource The address of the source Sniper token to clone
     * @return bullet The address of the newly cloned Bullet token
     * @return sniper The address of the newly cloned Sniper token
     */
    function cloneToken(
        address _optionAddress,
        address _bulletSource,
        address _sniperSource
    ) external returns (address bullet, address sniper);

    /**
     * @notice Clone an existing option pool for a new target address
     * @dev Creates a new option pool instance by cloning the specified target pool
     * @param _targetAddress The address of the target option pool to clone
     * @param _optionFactory The address of the option factory contract
     * @return option The address of the newly cloned option pool
     */
    function cloneOptionPool(address _targetAddress, address _optionFactory) external returns (address option);

    /**
     * @notice Create a new option contract with the specified parameters
     * @dev Generates a new option contract instance with the specified strike price, exercise timestamp, and option type
     * @param _strikePrice The strike price of the new option
     * @param _exerciseTimestamp The exercise timestamp of the new option
     * @param _optionType The type of the new option (i.e., call or put)
     * @param _optionFactory The address of the option factory contract
     * @return option The address of the newly created option contract
     */
    function createOptionContract(
        uint256 _strikePrice,
        uint256 _exerciseTimestamp,
        uint8 _optionType,
        address _optionFactory
    ) external returns (address option);
}