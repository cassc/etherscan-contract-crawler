// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aesthetically PixelTowns
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


contract AIPixelTowns is ERC721Creator {
    constructor() ERC721Creator("Aesthetically PixelTowns", "AIPixelTowns") {}
}