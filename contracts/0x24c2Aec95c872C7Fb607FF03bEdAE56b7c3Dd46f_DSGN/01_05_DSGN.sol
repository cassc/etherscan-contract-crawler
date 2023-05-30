// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DESIGN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    DESIGN    //
//              //
//              //
//////////////////


contract DSGN is ERC1155Creator {
    constructor() ERC1155Creator("DESIGN", "DSGN") {}
}