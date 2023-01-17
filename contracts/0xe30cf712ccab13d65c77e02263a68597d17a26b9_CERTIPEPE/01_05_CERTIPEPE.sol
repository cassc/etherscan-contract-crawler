// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Certified Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    PEPE    //
//            //
//            //
////////////////


contract CERTIPEPE is ERC721Creator {
    constructor() ERC721Creator("Certified Pepe", "CERTIPEPE") {}
}