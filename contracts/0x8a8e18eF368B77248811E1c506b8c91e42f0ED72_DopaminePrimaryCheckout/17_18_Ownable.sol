// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IOwnable} from "../interfaces/utils/IOwnable.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Ownable Contract
abstract contract Ownable is IOwnable {

    /// @notice Used for permanently revoking ownership.
    address public constant REVOKE_OWNER_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) {
            revert PendingOwnerOnly();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setPendingOwner(address newPendingOwner) public onlyOwner {
        if (pendingOwner == newPendingOwner) {
            revert PendingOwnerAlreadySet();
        }
        pendingOwner = newPendingOwner;
        emit PendingOwnerSet(newPendingOwner);
    }

    function renounceOwnership() public onlyOwner {
        if (pendingOwner != REVOKE_OWNER_ADDRESS) {
            revert PendingOwnerInvalid();
        }
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyPendingOwner {
        if (pendingOwner != newOwner) {
            revert PendingOwnerInvalid();
        }
        _transferOwnership(newOwner);
    }

    function supportsInterface(bytes4 id) public view virtual returns (bool);

    /// @notice Transfers ownership to address `newOwner`.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        pendingOwner = address(0);
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}