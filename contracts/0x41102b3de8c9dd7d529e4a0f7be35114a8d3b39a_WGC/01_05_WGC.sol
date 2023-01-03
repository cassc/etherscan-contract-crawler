// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wesley Gunn Creative
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//     __      __  ____    ____          //
//    /\ \  __/\ \/\  _`\ /\  _`\        //
//    \ \ \/\ \ \ \ \ \L\_\ \ \/\_\      //
//     \ \ \ \ \ \ \ \ \L_L\ \ \/_/_     //
//      \ \ \_/ \_\ \ \ \/, \ \ \L\ \    //
//       \ `\___x___/\ \____/\ \____/    //
//        '\/__//__/  \/___/  \/___/     //
//                                       //
//                                       //
///////////////////////////////////////////


contract WGC is ERC721Creator {
    constructor() ERC721Creator("Wesley Gunn Creative", "WGC") {}
}