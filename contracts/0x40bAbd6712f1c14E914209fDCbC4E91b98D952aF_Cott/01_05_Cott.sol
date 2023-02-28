// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: crypto trading dark elf
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Hello I'm Miyu♡    //
//                       //
//                       //
///////////////////////////


contract Cott is ERC721Creator {
    constructor() ERC721Creator("crypto trading dark elf", "Cott") {}
}