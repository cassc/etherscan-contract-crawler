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

import {ISimpleBlacklist} from "./ISimpleBlacklist.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library LibSimpleBlacklist {
    struct Storage {
        mapping(address => bool) accounts;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.blacklist.LibSimpleBlacklist");

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

    /*
     * @dev Emitted when an address was added to the blacklist
     * @param account The address of the account added to the blacklist
     * @param reason The reason string
     */
    event Blacklisted(address indexed account, string indexed reason);

    /*
     * @dev Emitted when an address was removed from the blacklist
     * @param account The address of the account removed from the blacklist
     * @param reason The reason string
     */
    event UnBlacklisted(address indexed account, string indexed reason);

    /**
     * @dev Revert with a standard message if `msg.sender` is blacklisted.
     */
    function enforceNotBlacklisted() internal view {
        checkBlacklisted(msg.sender);
    }

    /**
     * @dev Revert with a standard message if `account` is blacklisted.
     */
    function enforceNotBlacklisted(address account) internal view {
        checkBlacklisted(account);
    }

    /**
     * @dev Returns `true` if `account` is blacklisted.
     */
    function isBlacklisted(address account) internal view returns (bool) {
        return _storage().accounts[account];
    }

    /**
     * @dev Returns `true` if any address in `accounts` is on the blacklist.
     */
    function isBlacklisted(address[] memory accounts)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            if (isBlacklisted(accounts[index])) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Revert with a standard message if `account` is blacklisted.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^SimpleBlacklist: account (0x[0-9a-f]{40}) is blacklisted$/
     */
    function checkBlacklisted(address account) internal view {
        if (isBlacklisted(account)) {
            revert(
                string(
                    abi.encodePacked(
                        "SimpleBlacklist: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is blacklisted"
                    )
                )
            );
        }
    }

    /**
     * @dev Adds `account` to the blacklist.
     *
     * Internal function without access restriction.
     */
    function blacklist(address account, string memory reason) internal {
        if (!isBlacklisted(account)) {
            _storage().accounts[account] = true;
            emit Blacklisted(account, reason);
        }
    }

    /**
     * @dev Removes `account` from the blacklist.
     *
     * Internal function without access restriction.
     */
    function unblacklist(address account, string memory reason) internal {
        if (isBlacklisted(account)) {
            _storage().accounts[account] = false;
            emit UnBlacklisted(account, reason);
        }
    }
}