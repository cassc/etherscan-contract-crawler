// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crazy Land Official
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//      /$$$$$$  /$$        /$$$$$$     //
//     /$$__  $$| $$       /$$__  $$    //
//    | $$  \__/| $$      | $$  \ $$    //
//    | $$      | $$      | $$  | $$    //
//    | $$      | $$      | $$  | $$    //
//    | $$    $$| $$      | $$  | $$    //
//    |  $$$$$$/| $$$$$$$$|  $$$$$$/    //
//     \______/ |________/ \______/     //
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract CLO is ERC721Creator {
    constructor() ERC721Creator("Crazy Land Official", "CLO") {}
}