// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aesthetically MinimalxAnime
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


contract AIMxA is ERC721Creator {
    constructor() ERC721Creator("Aesthetically MinimalxAnime", "AIMxA") {}
}