// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Memes by 9256
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    The Memes by 9256             //
//                                  //
//    A Rememe Project              //
//    By @sertx92 and @mfer2355     //
//                                  //
//                                  //
//////////////////////////////////////


contract memes9256 is ERC1155Creator {
    constructor() ERC1155Creator("The Memes by 9256", "memes9256") {}
}