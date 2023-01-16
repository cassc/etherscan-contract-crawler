// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: stock trading elf
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    hello I'm Miyu    //
//                      //
//                      //
//////////////////////////


contract Tinya is ERC721Creator {
    constructor() ERC721Creator("stock trading elf", "Tinya") {}
}