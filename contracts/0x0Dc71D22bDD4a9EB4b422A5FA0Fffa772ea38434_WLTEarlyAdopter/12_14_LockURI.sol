// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LockURI
 * LockURI - Allows the owner to lock the base URI - not reversable
 */
abstract contract LockURI is Ownable{

    // Indicates if the owner can still change the metadata URI
    bool public isUriLocked;

    constructor() {
        isUriLocked = false;
    }

    /**
     * @dev For owner to lock the metadata URI - this is not reversable
     */
    function lockURI() public onlyOwner {
        isUriLocked = true;
    }

}