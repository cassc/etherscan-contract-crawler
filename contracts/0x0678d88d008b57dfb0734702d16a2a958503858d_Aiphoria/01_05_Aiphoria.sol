// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sounds Of Aiphoria
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                SOUNDS OF                                                                      //
//           _     ___________  ____    ____   ____   ________   ____      _                     //
//          dM.    `MM`MMMMMMMb.`MM'    `MM'  6MMMMb  `MMMMMMMb. `MM'     dM.                    //
//         ,MMb     MM MM    `Mb MM      MM  8P    Y8  MM    `Mb  MM     ,MMb                    //
//         d'YM.    MM MM     MM MM      MM 6M      Mb MM     MM  MM     d'YM.                   //
//        ,P `Mb    MM MM     MM MM      MM MM      MM MM     MM  MM    ,P `Mb                   //
//        d'  YM.   MM MM    .M9 MMMMMMMMMM MM      MM MM    .M9  MM    d'  YM.                  //
//       ,P   `Mb   MM MMMMMMM9' MM      MM MM      MM MMMMMMM9'  MM   ,P   `Mb                  //
//       d'    YM.  MM MM        MM      MM MM      MM MM  \M\    MM   d'    YM.                 //
//      ,MMMMMMMMb  MM MM        MM      MM YM      M9 MM   \M\   MM  ,MMMMMMMMb                 //
//      d'      YM. MM MM        MM      MM  8b    d8  MM    \M\  MM  d'      YM.                //
//    _dM_     _dMM_MM_MM_      _MM_    _MM_  YMMMM9  _MM_    \M\_MM_dM_     _dMM_               //
//                                                                                               //
//                                                                                               //
//                by Pixelord                                                                    //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract Aiphoria is ERC721Creator {
    constructor() ERC721Creator("Sounds Of Aiphoria", "Aiphoria") {}
}