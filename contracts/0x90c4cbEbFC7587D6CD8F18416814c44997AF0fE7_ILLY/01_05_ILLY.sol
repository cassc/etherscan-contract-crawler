// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Illegal Memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Illegal Memes    //
//                     //
//                     //
/////////////////////////


contract ILLY is ERC1155Creator {
    constructor() ERC1155Creator("Illegal Memes", "ILLY") {}
}