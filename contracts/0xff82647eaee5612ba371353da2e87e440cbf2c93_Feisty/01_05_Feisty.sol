// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feisty Doge Meme
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//     _____     _      _____     _     _           //
//    |   __|___| |_   |   __|___|_|___| |_ _ _     //
//    |  |  | -_|  _|  |   __| -_| |_ -|  _| | |    //
//    |_____|___|_|    |__|  |___|_|___|_| |_  |    //
//                                         |___|    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Feisty is ERC721Creator {
    constructor() ERC721Creator("Feisty Doge Meme", "Feisty") {}
}