// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fragments
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    //////////////////////////    //
//    /                        /    //
//    /     _     '         |  /    //
//    /             .          /    //
//    /    |     -      //     /    //
//    /                        /    //
//    //////////////////////////    //
//                                  //
//                                  //
//////////////////////////////////////


contract frg is ERC721Creator {
    constructor() ERC721Creator("Fragments", "frg") {}
}