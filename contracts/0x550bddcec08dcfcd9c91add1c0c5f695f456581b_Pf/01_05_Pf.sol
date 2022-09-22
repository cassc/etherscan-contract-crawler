// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Play with Fire
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    PLAY WITH FIRE    //
//                      //
//                      //
//////////////////////////


contract Pf is ERC721Creator {
    constructor() ERC721Creator("Play with Fire", "Pf") {}
}