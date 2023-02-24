// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sprann Freepass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Spfree    //
//              //
//              //
//////////////////


contract Spfree is ERC1155Creator {
    constructor() ERC1155Creator("Sprann Freepass", "Spfree") {}
}