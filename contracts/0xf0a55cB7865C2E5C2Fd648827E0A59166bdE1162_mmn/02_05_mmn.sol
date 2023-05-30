// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mrSucc
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Meme Man great adventures    //
//                                 //
//                                 //
/////////////////////////////////////


contract mmn is ERC721Creator {
    constructor() ERC721Creator("mrSucc", "mmn") {}
}