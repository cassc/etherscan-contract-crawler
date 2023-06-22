/*
Configuration

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IConfiguration.sol";
import "./OwnerController.sol";

/**
 * @title Configuration
 *
 * @notice configuration contract to define global variables for GYSR protocol
 */
contract Configuration is IConfiguration, OwnerController {
    // data
    mapping(bytes32 => uint256) private _data;
    mapping(address => mapping(bytes32 => uint256)) _overrides;

    /**
     * @inheritdoc IConfiguration
     */
    function setUint256(
        bytes32 key,
        uint256 value
    ) external override onlyController {
        _data[key] = value;
        emit ParameterUpdated(key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function setAddress(
        bytes32 key,
        address value
    ) external override onlyController {
        _data[key] = uint256(uint160(value));
        emit ParameterUpdated(key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function setAddressUint96(
        bytes32 key,
        address value0,
        uint96 value1
    ) external override onlyController {
        uint256 val = uint256(uint160(value0));
        val |= uint256(value1) << 160;
        _data[key] = val;
        emit ParameterUpdated(key, value0, value1);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function getUint256(bytes32 key) external view override returns (uint256) {
        if (_overrides[msg.sender][key] > 0) return _overrides[msg.sender][key];
        return _data[key];
    }

    /**
     * @inheritdoc IConfiguration
     */
    function getAddress(bytes32 key) external view override returns (address) {
        if (_overrides[msg.sender][key] > 0)
            return address(uint160(_overrides[msg.sender][key]));
        return address(uint160(_data[key]));
    }

    /**
     * @inheritdoc IConfiguration
     */
    function getAddressUint96(
        bytes32 key
    ) external view override returns (address, uint96) {
        uint256 val = _overrides[msg.sender][key] > 0
            ? _overrides[msg.sender][key]
            : _data[key];
        return (address(uint160(val)), uint96(val >> 160));
    }

    /**
     * @inheritdoc IConfiguration
     */
    function overrideUint256(
        address caller,
        bytes32 key,
        uint256 value
    ) external override onlyController {
        _overrides[caller][key] = value;
        emit ParameterOverridden(caller, key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function overrideAddress(
        address caller,
        bytes32 key,
        address value
    ) external override onlyController {
        uint256 val = uint256(uint160(value));
        _overrides[caller][key] = val;
        emit ParameterOverridden(caller, key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function overrideAddressUint96(
        address caller,
        bytes32 key,
        address value0,
        uint96 value1
    ) external override onlyController {
        uint256 val = uint256(uint160(value0));
        val |= uint256(value1) << 160;
        _overrides[caller][key] = val;
        emit ParameterOverridden(caller, key, value0, value1);
    }
}