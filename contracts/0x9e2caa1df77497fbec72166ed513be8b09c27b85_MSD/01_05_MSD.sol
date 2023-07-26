// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Midsummer Dream
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    ɯɐǝɹᗡɹǝɯɯnspᴉɯ    //
//                      //
//                      //
//////////////////////////


contract MSD is ERC721Creator {
    constructor() ERC721Creator("Midsummer Dream", "MSD") {}
}