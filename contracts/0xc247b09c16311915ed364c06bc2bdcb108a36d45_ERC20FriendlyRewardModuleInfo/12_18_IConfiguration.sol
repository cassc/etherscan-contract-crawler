/*
IConfiguration

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Configuration interface
 *
 * @notice this defines the protocol configuration interface
 */
interface IConfiguration {
    // events
    event ParameterUpdated(bytes32 indexed key, address value);
    event ParameterUpdated(bytes32 indexed key, uint256 value);
    event ParameterUpdated(bytes32 indexed key, address value0, uint96 value1);
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        uint256 value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value0,
        uint96 value1
    );

    /**
     * @notice set or update uint256 parameter
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function setUint256(bytes32 key, uint256 value) external;

    /**
     * @notice set or update address parameter
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function setAddress(bytes32 key, address value) external;

    /**
     * @notice set or update packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function setAddressUint96(
        bytes32 key,
        address value0,
        uint96 value1
    ) external;

    /**
     * @notice get uint256 parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice get address parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @notice get packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @return address parameter value
     * @return uint96 parameter value
     */
    function getAddressUint96(
        bytes32 key
    ) external view returns (address, uint96);

    /**
     * @notice override uint256 parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function overrideUint256(
        address caller,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function overrideAddress(
        address caller,
        bytes32 key,
        address value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function overrideAddressUint96(
        address caller,
        bytes32 key,
        address value0,
        uint96 value1
    ) external;
}