// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Transcendence: Isekai
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ▄▄▄· ▄▄▄ ..▄▄ · ▄▄▄▄▄ ▄ .▄▄▄▄ .▄▄▄▄▄▪   ▐ ▄ ▄▄▄▄▄     //
//    ▐█ ▀█ ▀▄.▀·▐█ ▀. •██  ██▪▐█▀▄.▀·•██  ██ •█▌▐█•██      //
//    ▄█▀▀█ ▐▀▀▪▄▄▀▀▀█▄ ▐█.▪██▀▐█▐▀▀▪▄ ▐█.▪▐█·▐█▐▐▌ ▐█.▪    //
//    ▐█ ▪▐▌▐█▄▄▌▐█▄▪▐█ ▐█▌·██▌▐▀▐█▄▄▌ ▐█▌·▐█▌██▐█▌ ▐█▌·    //
//     ▀  ▀  ▀▀▀  ▀▀▀▀  ▀▀▀ ▀▀▀ · ▀▀▀  ▀▀▀ ▀▀▀▀▀ █▪ ▀▀▀     //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract AiIsekai is ERC721Creator {
    constructor() ERC721Creator("Transcendence: Isekai", "AiIsekai") {}
}