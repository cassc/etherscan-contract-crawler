// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArirangDAO Token
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//           _     ________   ___________          _     ___      ___   ____       //
//          dM.    `MMMMMMMb. `MM`MMMMMMMb.       dM.    `MM\     `M'  6MMMMb/     //
//         ,MMb     MM    `Mb  MM MM    `Mb      ,MMb     MMM\     M  8P    YM     //
//         d'YM.    MM     MM  MM MM     MM      d'YM.    M\MM\    M 6M      Y     //
//        ,P `Mb    MM     MM  MM MM     MM     ,P `Mb    M \MM\   M MM            //
//        d'  YM.   MM    .M9  MM MM    .M9     d'  YM.   M  \MM\  M MM            //
//       ,P   `Mb   MMMMMMM9'  MM MMMMMMM9'    ,P   `Mb   M   \MM\ M MM     ___    //
//       d'    YM.  MM  \M\    MM MM  \M\      d'    YM.  M    \MM\M MM     `M'    //
//      ,MMMMMMMMb  MM   \M\   MM MM   \M\    ,MMMMMMMMb  M     \MMM YM      M     //
//      d'      YM. MM    \M\  MM MM    \M\   d'      YM. M      \MM  8b    d9     //
//    _dM_     _dMM_MM_    \M\_MM_MM_    \M\_dM_     _dMM_M_      \M   YMMMM9      //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract ARIT is ERC721Creator {
    constructor() ERC721Creator("ArirangDAO Token", "ARIT") {}
}