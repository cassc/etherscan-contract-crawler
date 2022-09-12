// SPDX-License-Identifier: MIT

// Developed by:
//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
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

import {LibSimpleBlacklist} from "./LibSimpleBlacklist.sol";
import {ISimpleBlacklist} from "./ISimpleBlacklist.sol";
import {LibUtils} from "../libraries/LibUtils.sol";

abstract contract SimpleBlacklistController is ISimpleBlacklist {
    /**
     * @dev External function to add `account` to the blacklist.
     *
     * See {ISimpleBlacklist-blacklist}
     *
     */
    function blacklist(address account, string calldata reason) external {
        LibUtils.enforceIsContractOwner();

        LibSimpleBlacklist.blacklist(account, reason);
    }

    /**
     * @dev External function to add `account` to the blacklist.
     *
     *
     * See {ISimpleBlacklist-blacklist}
     *
     */
    function blacklist(address[] calldata accounts, string[] calldata reasons)
        external
    {
        LibUtils.enforceIsContractOwner();

        if (reasons.length > 0) {
            // solhint-disable-next-line reason-string
            require(
                accounts.length == reasons.length,
                "SimpleBlacklist: Not enough reasons"
            );

            for (uint256 index = 0; index < accounts.length; index++) {
                LibSimpleBlacklist.blacklist(accounts[index], reasons[index]);
            }

            return;
        }

        for (uint256 index = 0; index < accounts.length; index++) {
            LibSimpleBlacklist.blacklist(accounts[index], "");
        }
    }

    /**
     * @dev External function to remove `account` from the blacklist.
     *
     * WARNING: This function is abstract, to enforce it's implementation
     *          in the final contract. This is important to make sure
     *          the final contraqct's access control mechanism will be used!
     *
     * See {ISimpleBlacklist-unblacklist}
     *
     */
    function unblacklist(address account, string calldata reason)
        external
        virtual
        override
    {
        LibUtils.enforceIsContractOwner();

        LibSimpleBlacklist.unblacklist(account, reason);
    }

    /**
     * @dev External function to add `account` to the blacklist.
     *
     * WARNING: This function is abstract, to enforce it's implementation
     *          in the final contract. This is important to make sure
     *          the final contraqct's access control mechanism will be used!
     *
     * See {ISimpleBlacklist-blacklist}
     *
     */
    function unblacklist(address[] calldata accounts, string[] calldata reasons)
        external
        virtual
        override
    {
        LibUtils.enforceIsContractOwner();

        if (reasons.length > 0) {
            // solhint-disable-next-line reason-string
            require(
                accounts.length == reasons.length,
                "SimpleBlacklist: Not enough reasons"
            );

            for (uint256 index = 0; index < accounts.length; index++) {
                LibSimpleBlacklist.unblacklist(accounts[index], reasons[index]);
            }

            return;
        }

        for (uint256 index = 0; index < accounts.length; index++) {
            LibSimpleBlacklist.unblacklist(accounts[index], "");
        }
    }

    /**
     * @dev Returns `true` if `account` is blacklisted.
     */
    function isBlacklisted(address account) external view returns (bool) {
        return LibSimpleBlacklist.isBlacklisted(account);
    }

    /**
     * @dev Returns `true` if any address in `accounts` is on the blacklist.
     */
    function isBlacklisted(address[] memory accounts)
        external
        view
        returns (bool)
    {
        return LibSimpleBlacklist.isBlacklisted(accounts);
    }
}