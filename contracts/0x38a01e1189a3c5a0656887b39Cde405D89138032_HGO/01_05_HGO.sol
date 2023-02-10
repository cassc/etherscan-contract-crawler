// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VITΛ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//      ___ ___  ____ ___  ________ ________       //
//     /   |   \|    |   \/  _____/ \_____  \      //
//    /    ~    \    |   /   \  ___  /   |   \     //
//    \    Y    /    |  /\    \_\  \/    |    \    //
//     \___|_  /|______/  \______  /\_______  /    //
//           \/                  \/         \/     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract HGO is ERC721Creator {
    constructor() ERC721Creator(unicode"VITΛ", "HGO") {}
}