// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is a set of accounts (authorized callers) that can be granted exclusive
 * access to specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOTCaller`, which can be applied to your functions to restrict their use
 * to authorized Open Town accounts.
 */
abstract contract OTCallable is Ownable {
    mapping(address => bool) private otCallers;

    event CallerAuthorized(address indexed caller, address indexed by);
    event CallerDeauthorized(address indexed caller, address indexed by);

    /**
     * @dev Throws if called by unauthorized account.
     */
    modifier onlyOTCaller() {
        require(otCallers[msg.sender], "OTCallable: Unauthorized caller");
        _;
    }

    /**
     * @dev Authorizes new account (`addr`).
     * Can only be called by the current owner.
     */
    function authorizeCaller(address addr) external onlyOwner {
        otCallers[addr] = true;
        emit CallerAuthorized(addr, msg.sender);
    }

    /**
     * @dev Revokes authorization from the account (`addr`).
     * Can only be called by the current owner.
     */
    function deauthorizeCaller(address addr) external onlyOwner {
        otCallers[addr] = false;
        emit CallerDeauthorized(addr, msg.sender);
    }
}