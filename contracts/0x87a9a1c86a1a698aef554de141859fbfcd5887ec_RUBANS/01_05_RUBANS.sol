// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: À Propos des Rubans
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    RUBANS    //
//              //
//              //
//////////////////


contract RUBANS is ERC721Creator {
    constructor() ERC721Creator(unicode"À Propos des Rubans", "RUBANS") {}
}