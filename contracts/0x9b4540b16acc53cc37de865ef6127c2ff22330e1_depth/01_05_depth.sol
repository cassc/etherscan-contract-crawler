// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pooyazi [editions]
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                              .__     //
//    ______   ____   ____ ___.__._____  _______|__|    //
//    \____ \ /  _ \ /  _ <   |  |\__  \ \___   /  |    //
//    |  |_> >  <_> |  <_> )___  | / __ \_/    /|  |    //
//    |   __/ \____/ \____// ____|(____  /_____ \__|    //
//    |__|                 \/          \/      \/       //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract depth is ERC721Creator {
    constructor() ERC721Creator("pooyazi [editions]", "depth") {}
}