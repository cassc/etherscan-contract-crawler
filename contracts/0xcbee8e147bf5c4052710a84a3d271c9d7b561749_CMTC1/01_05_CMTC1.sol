// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CM Test Contract 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//    _________     _________________________  ____     //
//    \_   ___ \   /     \__    ___/\_   ___ \/_   |    //
//    /    \  \/  /  \ /  \|    |   /    \  \/ |   |    //
//    \     \____/    Y    \    |   \     \____|   |    //
//     \______  /\____|__  /____|    \______  /|___|    //
//            \/         \/                 \/          //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract CMTC1 is ERC721Creator {
    constructor() ERC721Creator("CM Test Contract 1", "CMTC1") {}
}