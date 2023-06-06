// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feels good man. Apple Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      __   __             __                      //
//     /    /  |      /    /    /                   //
//    (___ (___| ___ (___ ( __    ___  ___          //
//        )|   )|   )|    |   )| |   )|___ \   )    //
//     __/ |__/ |  / |__  |__/ | |__/  __/  \_/     //
//                               |           /      //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract fgm is ERC1155Creator {
    constructor() ERC1155Creator("Feels good man. Apple Edition", "fgm") {}
}