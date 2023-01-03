// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kittenbnb
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    kittenbnb    //
//                 //
//                 //
/////////////////////


contract KBNB is ERC721Creator {
    constructor() ERC721Creator("Kittenbnb", "KBNB") {}
}