// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: smART
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                 ___   ___  ______    //
//      ___ __ _  / _ | / _ \/_  __/    //
//     (_-</  ' \/ __ |/ , _/ / /       //
//    /___/_/_/_/_/ |_/_/|_| /_/        //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract smART is ERC721Creator {
    constructor() ERC721Creator("smART", "smART") {}
}