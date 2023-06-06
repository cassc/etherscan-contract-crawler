// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

/// @dev diamond storage slot `keccak256("diamond.storage.ownable")`
bytes32 constant DIAMOND_STORAGE_OWNABLE = 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- external ------------- */

    function owner() public view returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != s().owner) revert CallerNotOwner();
        _;
    }
}