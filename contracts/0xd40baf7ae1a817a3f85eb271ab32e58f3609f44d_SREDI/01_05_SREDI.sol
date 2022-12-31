// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sarah Ridgley Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//                                       //
//       d888888o.   8 888888888o.       //
//     .`8888:' `88. 8 8888    `88.      //
//     8.`8888.   Y8 8 8888     `88      //
//     `8.`8888.     8 8888     ,88      //
//      `8.`8888.    8 8888.   ,88'      //
//       `8.`8888.   8 888888888P'       //
//        `8.`8888.  8 8888`8b           //
//    8b   `8.`8888. 8 8888 `8b.         //
//    `8b.  ;8.`8888 8 8888   `8b.       //
//     `Y8888P ,88P' 8 8888     `88.     //
//                                       //
//                                       //
///////////////////////////////////////////


contract SREDI is ERC721Creator {
    constructor() ERC721Creator("Sarah Ridgley Editions", "SREDI") {}
}