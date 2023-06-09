// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brainyy 1of1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      .         ,__   .  ____   .___      .       //
//     /|    __.  /  ` /|  /   \  /   \    /|       //
//      |  .'   \ |__   |  |,_-<  |__-'   /  \      //
//      |  |    | |     |  |    ` |  \   /---'\     //
//     _|_  `._.' |    _|_ `----' /   \,'      \    //
//                /                                 //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract BRA1of1 is ERC721Creator {
    constructor() ERC721Creator("Brainyy 1of1", "BRA1of1") {}
}