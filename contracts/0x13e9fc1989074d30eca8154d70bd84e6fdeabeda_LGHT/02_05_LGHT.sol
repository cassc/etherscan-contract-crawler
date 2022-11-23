// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    |\|()(|2\/\/|_    //
//                      //
//                      //
//////////////////////////


contract LGHT is ERC721Creator {
    constructor() ERC721Creator("Light", "LGHT") {}
}