// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meme Of Thrones
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Meme Of Thrones by 761026    //
//                                 //
//                                 //
/////////////////////////////////////


contract MemeOfThrones is ERC1155Creator {
    constructor() ERC1155Creator("Meme Of Thrones", "MemeOfThrones") {}
}