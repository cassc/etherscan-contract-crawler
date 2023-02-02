// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yuz pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//     __    __  __    __  ________     //
//    |  \  |  \|  \  |  \|        \    //
//    | $$  | $$| $$  | $$ \$$$$$$$$    //
//    | $$  | $$| $$  | $$  /    $$     //
//    | $$__/ $$| $$__/ $$ /  $$$$_     //
//     \$$    $$ \$$    $$|  $$    \    //
//     _\$$$$$$$  \$$$$$$  \$$$$$$$$    //
//    |  \__| $$                        //
//     \$$    $$                        //
//      \$$$$$$                         //
//                                      //
//                                      //
//////////////////////////////////////////


contract yuzpass is ERC1155Creator {
    constructor() ERC1155Creator("yuz pass", "yuzpass") {}
}