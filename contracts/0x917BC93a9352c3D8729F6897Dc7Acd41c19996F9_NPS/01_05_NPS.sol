// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nps3D Animation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//      _   _ _____   _____ ____  _____      //
//     | \ | |  __ \ / ____|___ \|  __ \     //
//     |  \| | |__) | (___   __) | |  | |    //
//     | . ` |  ___/ \___ \ |__ <| |  | |    //
//     | |\  | |     ____) |___) | |__| |    //
//     |_| \_|_|    |_____/|____/|_____/     //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract NPS is ERC1155Creator {
    constructor() ERC1155Creator("Nps3D Animation", "NPS") {}
}