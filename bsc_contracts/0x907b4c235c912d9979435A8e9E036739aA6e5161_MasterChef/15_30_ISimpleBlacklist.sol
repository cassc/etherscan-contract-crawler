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

/*
 * @dev External interface of a simple blacklist.
 */
interface ISimpleBlacklist {
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

    /*
     * @dev Check if `account` is on the blacklist.
     */
    function isBlacklisted(address account) external view returns (bool);

    /*
     * @dev Check if any address in `accounts` is on the blacklist.
     */
    function isBlacklisted(address[] memory accounts)
        external
        view
        returns (bool);

    /*
     * @dev Adds `account` to the blacklist with `reason`.
     *
     * The `reason` is optional and can be an empty string.
     *
     * Emits {Blacklisted} event, if `account` was added to the blacklist.
     */
    function blacklist(address account, string calldata reason) external;

    /*
     * @dev Adds `accounts` to the blacklist with `reasons`.
     *
     * The `reasons` is optional and can be an array of empty strings.
     * Length of the `accounts`and `reasons` arrays must be equal.
     *
     * Emits {Blacklisted} events, for each account that was added to the blacklist
     */
    function blacklist(address[] calldata accounts, string[] calldata reasons)
        external;

    /*
     * @dev Removes `account` from the blacklist with `reason`.
     *
     * The `reason` is optional and can be an empty string.
     *
     * Emits {UnBlacklisted} event, if `account` was removed from the blacklist
     */
    function unblacklist(address account, string calldata reason) external;

    /*
     * @dev Removes multiple `accounts` from the blacklist with `reasons`.
     *
     * The `reasons` is optional and can be an array of empty strings.
     * Length of the `accounts`and `reasons` arrays must be equal.
     *
     * Emits {UnBlacklisted} events, for each account that was removed from the blacklist
     */
    function unblacklist(address[] calldata accounts, string[] calldata reasons)
        external;
}