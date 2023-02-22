// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vrubel's Demons
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    by whatisiana    //
//                     //
//                     //
/////////////////////////


contract DMNS is ERC721Creator {
    constructor() ERC721Creator("Vrubel's Demons", "DMNS") {}
}