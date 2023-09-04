// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Auth} from "chronicle-std/auth/Auth.sol";

import {ITorAddressRegister} from "./ITorAddressRegister.sol";

/**
 * @title TorAddressRegister
 *
 * @notice The `TorAddressRegister` contract provides a register for tor
 *         addresses.
 *
 * @dev The contract uses the `chronicle-std/Auth` module for access control.
 *      While the register is publicly readable, state mutating functions are
 *      only callable by auth'ed addresses.
 *
 *      Note that the register does not guarantee stable ordering, may contain
 *      duplicates, and does not sanity-check newly added tor addresses.
 */
contract TorAddressRegister is ITorAddressRegister, Auth {
    /// @dev May contain duplicates.
    /// @dev Stable ordering not guaranteed.
    /// @dev May contain the empty string or other invalid tor addresses.
    string[] private _register;

    constructor(address initialAuthed) Auth(initialAuthed) {}

    /// @inheritdoc ITorAddressRegister
    function get(uint index) external view returns (string memory) {
        if (index >= _register.length) {
            revert IndexOutOfBounds(index, _register.length);
        }

        return _register[index];
    }

    /// @inheritdoc ITorAddressRegister
    function tryGet(uint index) external view returns (bool, string memory) {
        if (index >= _register.length) {
            return (false, "");
        } else {
            return (true, _register[index]);
        }
    }

    /// @inheritdoc ITorAddressRegister
    function list() external view returns (string[] memory) {
        return _register;
    }

    /// @inheritdoc ITorAddressRegister
    function count() external view returns (uint) {
        return _register.length;
    }

    /// @inheritdoc ITorAddressRegister
    function add(string calldata torAddress) external auth {
        _register.push(torAddress);
        emit TorAddressAdded(msg.sender, torAddress);
    }

    /// @inheritdoc ITorAddressRegister
    function add(string[] calldata torAddresses) external auth {
        for (uint i; i < torAddresses.length; i++) {
            _register.push(torAddresses[i]);
            emit TorAddressAdded(msg.sender, torAddresses[i]);
        }
    }

    /// @inheritdoc ITorAddressRegister
    /// @dev Note to not provide a "bulk remove" function as the ordering of tor
    ///      addresses inside the register may change during removal.
    function remove(uint index) external auth {
        if (index >= _register.length) {
            revert IndexOutOfBounds(index, _register.length);
        }

        emit TorAddressRemoved(msg.sender, _register[index]);
        _register[index] = _register[_register.length - 1];
        _register.pop();
    }
}

/**
 * @dev Contract overwrite to deploy contract instances with specific naming.
 *
 *      For more info, see docs/Deployment.md.
 */
contract TorAddressRegister_Relays_1 is TorAddressRegister {
    constructor(address initialAuthed) TorAddressRegister(initialAuthed) {}
}