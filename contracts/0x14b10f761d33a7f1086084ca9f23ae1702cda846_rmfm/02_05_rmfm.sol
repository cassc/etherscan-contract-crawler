// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rare mfer memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    rare mfer memes    //
//                       //
//                       //
///////////////////////////


contract rmfm is ERC1155Creator {
    constructor() ERC1155Creator("rare mfer memes", "rmfm") {}
}