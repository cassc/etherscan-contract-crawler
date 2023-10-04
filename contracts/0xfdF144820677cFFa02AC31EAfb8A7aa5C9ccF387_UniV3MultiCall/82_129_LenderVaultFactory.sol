// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Errors} from "../Errors.sol";
import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";
import {ILenderVaultFactory} from "./interfaces/ILenderVaultFactory.sol";
import {ILenderVaultImpl} from "./interfaces/ILenderVaultImpl.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

contract LenderVaultFactory is ReentrancyGuard, ILenderVaultFactory {
    address public immutable addressRegistry;
    address public immutable lenderVaultImpl;

    constructor(address _addressRegistry, address _lenderVaultImpl) {
        if (_addressRegistry == address(0) || _lenderVaultImpl == address(0)) {
            revert Errors.InvalidAddress();
        }
        addressRegistry = _addressRegistry;
        lenderVaultImpl = _lenderVaultImpl;
    }

    function createVault(
        bytes32 salt
    ) external nonReentrant returns (address newLenderVaultAddr) {
        newLenderVaultAddr = Clones.cloneDeterministic(
            lenderVaultImpl,
            keccak256(abi.encode(msg.sender, salt))
        );
        ILenderVaultImpl(newLenderVaultAddr).initialize(
            msg.sender,
            addressRegistry
        );
        uint256 numRegisteredVaults = IAddressRegistry(addressRegistry)
            .addLenderVault(newLenderVaultAddr);
        address mysoTokenManager = IAddressRegistry(addressRegistry)
            .mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager).processP2PCreateVault(
                numRegisteredVaults,
                msg.sender,
                newLenderVaultAddr
            );
        }
        emit NewVaultCreated(
            newLenderVaultAddr,
            msg.sender,
            numRegisteredVaults
        );
    }
}