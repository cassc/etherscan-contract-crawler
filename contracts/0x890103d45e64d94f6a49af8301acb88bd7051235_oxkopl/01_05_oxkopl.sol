// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xkopil
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    0xkopi    //
//              //
//              //
//////////////////


contract oxkopl is ERC721Creator {
    constructor() ERC721Creator("0xkopil", "oxkopl") {}
}