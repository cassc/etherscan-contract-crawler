// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Auth} from "chronicle-std/auth/Auth.sol";
import {Toll} from "chronicle-std/toll/Toll.sol";

import {IGreenhouse} from "./IGreenhouse.sol";

import {LibCREATE3} from "./libs/LibCREATE3.sol";

/**
 * @title Greenhouse
 * @custom:version 1.0.0
 *
 * @notice A greenhouse to plant contracts using CREATE3
 *
 * @dev Greenhouse is a contract factory planting contracts at deterministic
 *      addresses. The address of the planted contract solely depends on the
 *      provided salt.
 *
 *      The contract uses `chronicle-std`'s `Auth` module to grant addresses
 *      access to protected functions. `chronicle-std`'s `Toll` module is
 *      utilized to determine which addresses are eligible to plant new
 *      contracts. Note that auth'ed addresses are _not_ eligible to plant new
 *      contracts.
 */
contract Greenhouse is IGreenhouse, Auth, Toll {
    constructor(address initialAuthed) Auth(initialAuthed) {}

    /// @inheritdoc IGreenhouse
    ///
    /// @custom:invariant Planted contract's address is deterministic and solely
    ///                   depends on `salt`.
    ///                     ∀s ∊ bytes32: plant(s, _) = addressOf(s)
    function plant(bytes32 salt, bytes memory creationCode)
        external
        toll
        returns (address)
    {
        if (salt == bytes32(0)) {
            revert EmptySalt();
        }
        if (creationCode.length == 0) {
            revert EmptyCreationCode();
        }

        if (addressOf(salt).code.length != 0) {
            revert AlreadyPlanted(salt);
        }

        bool ok;
        address addr;
        (ok, addr) = LibCREATE3.tryDeploy(salt, creationCode);
        if (!ok) {
            revert PlantingFailed(salt);
        }
        // assert(addr == addressOf(salt));

        emit Planted(msg.sender, salt, addr);

        return addr;
    }

    /// @inheritdoc IGreenhouse
    function addressOf(bytes32 salt) public view returns (address) {
        return LibCREATE3.addressOf(salt);
    }

    /// @dev Defines authorization for IToll's authenticated functions.
    function toll_auth() internal override(Toll) auth {}
}