// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Notable Memes (Or Not)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//    THIS MEME MAY OR MAY NOT BE NOTABLE    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MEME is ERC1155Creator {
    constructor() ERC1155Creator("Notable Memes (Or Not)", "MEME") {}
}