// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kvlt Photo by Kvlt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ▄ •▄ ▌ ▐▄▄▌▄▄▄▄▄     ▄▄▄·▄ .▄   ▄▄▄▄▄         //
//    █▌▄▌▪█·███••██      ▐█ ▄██▪▐▪   •██ ▪         //
//    ▐▀▀▄▐█▐███▪ ▐█.▪     ██▀██▀▐█▄█▀▄▐█.▪▄█▀▄     //
//    ▐█.█▌███▐█▌▐▐█▌·    ▐█▪·██▌▐▐█▌.▐▐█▌▐█▌.▐▌    //
//    ·▀  . ▀ .▀▀▀▀▀▀     .▀  ▀▀▀ ·▀█▄▀▀▀▀ ▀█▄▀▪    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract KP is ERC721Creator {
    constructor() ERC721Creator("Kvlt Photo by Kvlt", "KP") {}
}