// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ☯️ 💚 🐸
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Peace, Love Unity, Respect ✌️    //
//                                     //
//                                     //
/////////////////////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator(unicode"☯️ 💚 🐸", "PEPE") {}
}