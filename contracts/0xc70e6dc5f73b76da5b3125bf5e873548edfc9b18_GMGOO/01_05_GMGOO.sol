// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM jar
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    GM GOO    //
//              //
//              //
//////////////////


contract GMGOO is ERC1155Creator {
    constructor() ERC1155Creator("GM jar", "GMGOO") {}
}