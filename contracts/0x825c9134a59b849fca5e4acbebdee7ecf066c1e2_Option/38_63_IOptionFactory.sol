// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IOptionFactory interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for managing option factory contracts
 */
interface IOptionFactory {
    /**
     * @notice Get the ID of the last created option contract
     * @dev Returns the ID of the last created option contract
     * @return The ID of the last created option contract
     */
    function getLastOptionId() external view returns (uint);

    /**
     * @notice Create a new option contract with the specified parameters
     * @dev Creates a new option contract with the specified strike price, start timestamp, exercise timestamp, and option type
     * @param _strikePrice The strike price of the option
     * @param _startTimestamp The start timestamp of the option
     * @param _exerciseTimestamp The exercise timestamp of the option
     * @param _optionType The type of the option (i.e., call or put)
     * @return optionID The ID of the newly created option contract
     */
    function createOption(
        uint256 _strikePrice,
        uint256 _startTimestamp,
        uint256 _exerciseTimestamp,
        uint8 _optionType
    ) external returns (uint256 optionID);

    /**
     * @notice Get the address of the option contract with the specified ID
     * @dev Returns the address of the option contract with the specified ID
     * @param _optionID The ID of the option contract to retrieve the address for
     * @return The address of the option contract
     */
    function getOptionByID(uint256 _optionID) external view returns (address);

    /**
     * @notice Get the address of the staking pool contract
     * @dev Returns the address of the staking pool contract
     * @return The address of the staking pool contract
     */
    function getStakingPools() external view returns (address);

    /**
     * @notice Get the address of the distributions contract
     * @dev Returns the address of the distributions contract
     * @return The address of the distributions contract
     */
    function distributions() external view returns (address);
}