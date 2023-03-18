// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe OE by Matt Furie (Redeploy)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    PEPE    //
//            //
//            //
////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("Pepe OE by Matt Furie (Redeploy)", "PEPE") {}
}