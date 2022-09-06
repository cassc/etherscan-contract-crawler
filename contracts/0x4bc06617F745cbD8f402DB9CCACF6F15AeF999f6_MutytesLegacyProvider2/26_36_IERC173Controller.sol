// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface required by controller functions
 */
interface IERC173Controller {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}