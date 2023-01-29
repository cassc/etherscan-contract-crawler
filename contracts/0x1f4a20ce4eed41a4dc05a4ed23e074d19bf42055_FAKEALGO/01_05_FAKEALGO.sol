// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKEALGO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    FAHJ    //
//            //
//            //
////////////////


contract FAKEALGO is ERC1155Creator {
    constructor() ERC1155Creator("FAKEALGO", "FAKEALGO") {}
}