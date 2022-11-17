// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {Clones} from "openzeppelin/contracts/proxy/Clones.sol";

import {Guarded} from "fiat/utils/Guarded.sol";

interface IVaultInitializable {
    function initialize(bytes calldata params) external;
}

/// @title VaultFactory
/// @notice Instantiates proxy vault contracts
contract VaultFactory is Guarded {
    event VaultCreated(address indexed instance, address indexed creator, bytes params);

    function createVault(address impl, bytes calldata params) external checkCaller returns (address) {
        address instance = Clones.clone(impl);

        // append msg.sender to set the root
        IVaultInitializable(instance).initialize(abi.encodePacked(params, abi.encode(msg.sender)));

        emit VaultCreated(instance, msg.sender, params);

        return instance;
    }
}