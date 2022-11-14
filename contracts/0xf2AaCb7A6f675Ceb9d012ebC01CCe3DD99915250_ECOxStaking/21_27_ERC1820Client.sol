// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

/** @title Utilities for interfacing with ERC1820
 */
abstract contract ERC1820Client {
    IERC1820Registry internal constant ERC1820REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
}