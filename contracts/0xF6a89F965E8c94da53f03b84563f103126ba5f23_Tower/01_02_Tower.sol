// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./TwoStepOwnable.sol";

/// @title Tower
/// @notice Utility contract that stores addresses of any contracts
contract Tower is TwoStepOwnable {
    mapping(bytes32 => address) private _coordinates;

    error AddressZero();
    error KeyIsTaken();
    error EmptyCoordinates();

    event NewCoordinates(string key, address indexed newContract);
    event UpdateCoordinates(string key, address indexed newContract);
    event RemovedCoordinates(string key);

    /// @param _key string key
    /// @return address coordinates for the `_key`
    function coordinates(string calldata _key) external view virtual returns (address) {
        return _coordinates[makeKey(_key)];
    }

    /// @param _key raw bytes32 key
    /// @return address coordinates for the raw `_key`
    function rawCoordinates(bytes32 _key) external view virtual returns (address) {
        return _coordinates[_key];
    }

    /// @dev Registering new contract
    /// @param _key key under which contract will be stored
    /// @param _contract contract address
    function register(string calldata _key, address _contract) external virtual onlyOwner {
        bytes32 key = makeKey(_key);
        if (_coordinates[key] != address(0)) revert KeyIsTaken();
        if (_contract == address(0)) revert AddressZero();

        _coordinates[key] = _contract;
        emit NewCoordinates(_key, _contract);
    }

    /// @dev Removing coordinates
    /// @param _key key to remove
    function unregister(string calldata _key) external virtual onlyOwner {
        bytes32 key = makeKey(_key);
        if (_coordinates[key] == address(0)) revert EmptyCoordinates();

        _coordinates[key] = address(0);
        emit RemovedCoordinates(_key);
    }

    /// @dev Update key with new contract address
    /// @param _key key under which new contract will be stored
    /// @param _contract contract address
    function update(string calldata _key, address _contract) external virtual onlyOwner {
        bytes32 key = makeKey(_key);
        if (_coordinates[key] == address(0)) revert EmptyCoordinates();
        if (_contract == address(0)) revert AddressZero();

        _coordinates[key] = _contract;
        emit UpdateCoordinates(_key, _contract);
    }

    /// @dev generating mapping key based on string
    /// @param _key string key
    /// @return bytes32 representation of the `_key`
    function makeKey(string calldata _key) public pure virtual returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }
}