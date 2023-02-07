// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Memes By Bizzle
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Bizzle's take on the memes    //
//                                  //
//                                  //
//////////////////////////////////////


contract MBB is ERC1155Creator {
    constructor() ERC1155Creator("The Memes By Bizzle", "MBB") {}
}