// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aesthetically Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract AIEds is ERC1155Creator {
    constructor() ERC1155Creator("Aesthetically Editions", "AIEds") {}
}