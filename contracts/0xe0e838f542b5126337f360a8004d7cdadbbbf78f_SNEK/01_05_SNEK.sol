// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Snek
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     6MMMMb\`MM\     `M'`MMMMMMMMM `MM    d'  @    //
//    6M'    ` MMM\     M  MM      \  MM   d'        //
//    MM       M\MM\    M  MM         MM  d'         //
//    YM.      M \MM\   M  MM    ,    MM d'          //
//     YMMMMb  M  \MM\  M  MMMMMMM    MMd'           //
//         `Mb M   \MM\ M  MM    `    MMYM.          //
//          MM M    \MM\M  MM         MM YM.         //
//          MM M     \MMM  MM         MM  YM.        //
//    L    ,M9 M      \MM  MM      /  MM   YM.       //
//    MYMMMM9 _M_      \M _MMMMMMMMM _MM_   YM._     //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SNEK is ERC721Creator {
    constructor() ERC721Creator("Snek", "SNEK") {}
}