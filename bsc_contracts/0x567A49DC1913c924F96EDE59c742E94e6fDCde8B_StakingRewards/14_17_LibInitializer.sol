// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IInitializer} from "./IInitializer.sol";

library LibInitializer {
    struct Storage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint8 initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool initializing;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.utils.initializer.LibInitializer");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            s.slot := slot
        }
        // solhint-enable
    }

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    function enforceIsInitializing() internal view {
        if (!isInitializing()) {
            revert IInitializer.InitializerContractIsNotInitializing();
        }
    }

    function isInitializing() internal view returns (bool) {
        return _storage().initializing;
    }

    function setInitializing(bool value) internal {
        _storage().initializing = value;
    }

    function isInitialized() internal view returns (bool) {
        return isInitialized(1);
    }

    function isInitialized(uint8 version) internal view returns (bool) {
        return _storage().initialized >= version;
    }

    function getInitializedVersion() internal view returns (uint8) {
        return _storage().initialized;
    }

    function setInitialized(uint8 version) internal {
        if (isInitialized(version)) {
            revert IInitializer.InitializerVersionAlreadyInitialized(version);
        }

        _storage().initialized = version;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function disable() internal {
        if (isInitializing()) {
            revert IInitializer.InitializerContractIsInitializing();
        }

        if (!isInitialized(type(uint8).max)) {
            setInitialized(type(uint8).max);
            emit Initialized(type(uint8).max);
        }
    }
}