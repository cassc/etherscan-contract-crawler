// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bthd
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    bthd    //
//            //
//            //
////////////////


contract bthd is ERC721Creator {
    constructor() ERC721Creator("bthd", "bthd") {}
}