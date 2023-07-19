// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGyroConfig.sol";
import "GovernableUpgradeable.sol";
import "EnumerableMapping.sol";

contract GyroConfig is IGyroConfig, GovernableUpgradeable {
    using EnumerableMapping for EnumerableMapping.Bytes32ToUIntMap;

    uint8 internal constant ADDRESS_TYPE = 1;
    uint8 internal constant UINT_TYPE = 2;

    /// @notice Actual configuration values
    mapping(bytes32 => uint256) internal _config;

    /// @notice Configuration metadata such as existence, type, and frozen status
    EnumerableMapping.Bytes32ToUIntMap internal _configMeta;

    /// @inheritdoc IGyroConfig
    function listKeys() external view override returns (bytes32[] memory) {
        uint256 length = _configMeta.length();
        bytes32[] memory keys = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            (keys[i], ) = _configMeta.at(i);
        }
        return keys;
    }

    /// @inheritdoc IGyroConfig
    function hasKey(bytes32 key) external view override returns (bool) {
        return _configMeta.contains(key);
    }

    /// @inheritdoc IGyroConfig
    function getConfigMeta(bytes32 key) external view override returns (uint8, bool) {
        (bool exists, uint8 configType, bool frozen) = _getConfigMeta(key);
        require(exists, Errors.KEY_NOT_FOUND);
        return (configType, frozen);
    }

    /// @inheritdoc IGyroConfig
    function getUint(bytes32 key) external view override returns (uint256) {
        return _get(key, UINT_TYPE);
    }

    /// @inheritdoc IGyroConfig
    function getUint(bytes32 key, uint256 defaultValue) external view override returns (uint256) {
        return _get(key, UINT_TYPE, defaultValue);
    }

    /// @inheritdoc IGyroConfig
    function getAddress(bytes32 key) external view override returns (address) {
        return address(uint160(_get(key, ADDRESS_TYPE)));
    }

    /// @inheritdoc IGyroConfig
    function getAddress(bytes32 key, address defaultValue)
        external
        view
        override
        returns (address)
    {
        return address(uint160(_get(key, ADDRESS_TYPE, uint256(uint160(defaultValue)))));
    }

    /// @inheritdoc IGyroConfig
    function setUint(bytes32 key, uint256 newValue) external override governanceOnly {
        uint256 oldValue = _set(key, newValue, UINT_TYPE);
        emit ConfigChanged(key, oldValue, newValue);
    }

    /// @inheritdoc IGyroConfig
    function setAddress(bytes32 key, address newValue) external override governanceOnly {
        uint256 oldValue = _set(key, uint256(uint160(newValue)), ADDRESS_TYPE);
        emit ConfigChanged(key, address(uint160(oldValue)), newValue);
    }

    /// @inheritdoc IGyroConfig
    function unset(bytes32 key) external override governanceOnly {
        (bool exists, , bool frozen) = _getConfigMeta(key);
        require(exists, Errors.KEY_NOT_FOUND);
        require(!frozen, Errors.KEY_FROZEN);
        delete _config[key];
        _configMeta.remove(key);
        emit ConfigUnset(key);
    }

    /// @inheritdoc IGyroConfig
    function freeze(bytes32 key) external governanceOnly {
        (bool exists, uint8 configType, bool frozen) = _getConfigMeta(key);
        require(exists, Errors.KEY_NOT_FOUND);
        require(!frozen, Errors.KEY_FROZEN);
        _setConfigMeta(key, configType, true);

        emit ConfigFrozen(key);
    }

    function _get(bytes32 key, uint8 expectedType) internal view returns (uint256) {
        (bool exists, uint8 configType, ) = _getConfigMeta(key);
        require(exists && configType == expectedType, Errors.KEY_NOT_FOUND);
        return _config[key];
    }

    function _get(
        bytes32 key,
        uint8 expectedType,
        uint256 defaultValue
    ) internal view returns (uint256) {
        (bool exists, uint8 configType, ) = _getConfigMeta(key);
        if (!exists) return defaultValue;
        require(configType == expectedType, Errors.KEY_NOT_FOUND);
        return _config[key];
    }

    function _set(
        bytes32 key,
        uint256 newValue,
        uint8 expectedType
    ) internal returns (uint256) {
        (bool exists, uint8 configType, bool frozen) = _getConfigMeta(key);
        require(!exists || configType == expectedType, Errors.INVALID_ARGUMENT);
        require(!frozen, Errors.KEY_FROZEN);
        uint256 oldValue = _config[key];
        _config[key] = newValue;
        _setConfigMeta(key, expectedType, false);
        return oldValue;
    }

    function _setConfigMeta(
        bytes32 key,
        uint8 configType,
        bool frozen
    ) internal {
        uint256 frozenB = frozen ? 1 : 0;
        uint256 value = (uint256(configType) << 8) | frozenB;
        _configMeta.set(key, value);
    }

    function _getConfigMeta(bytes32 key)
        internal
        view
        returns (
            bool exists,
            uint8 configType,
            bool frozen
        )
    {
        uint256 meta;
        (exists, meta) = _configMeta.tryGet(key);
        if (exists) {
            frozen = meta & 0x1 == 1;
            configType = uint8(meta >> 8);
        }
    }
}