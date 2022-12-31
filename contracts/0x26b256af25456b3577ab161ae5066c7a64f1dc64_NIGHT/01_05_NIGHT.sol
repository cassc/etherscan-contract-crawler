// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memoirs of Midnight
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Memoirs of Midnight    //
//    -Alister Mori          //
//                           //
//                           //
///////////////////////////////


contract NIGHT is ERC721Creator {
    constructor() ERC721Creator("Memoirs of Midnight", "NIGHT") {}
}