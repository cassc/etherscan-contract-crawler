// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VRCot
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     _   _______  _____       _       //
//    | | | | ___ \/  __ \     | |      //
//    | | | | |_/ /| /  \/ ___ | |_     //
//    | | | |    / | |    / _ \| __|    //
//    \ \_/ / |\ \ | \__/\ (_) | |_     //
//     \___/\_| \_| \____/\___/ \__|    //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract VRCot is ERC721Creator {
    constructor() ERC721Creator("VRCot", "VRCot") {}
}