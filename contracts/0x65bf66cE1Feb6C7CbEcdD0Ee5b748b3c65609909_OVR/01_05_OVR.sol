// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manic Overgrowth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//          ___.    _____                   //
//    _____ \_ |___/ ____\______  ____      //
//    \__  \ | __ \   __\\_  __ \/  _ \     //
//     / __ \| \_\ \  |   |  | \(  <_> )    //
//    (____  /___  /__|   |__|   \____/     //
//         \/    \/                         //
//                                          //
//                                          //
//////////////////////////////////////////////


contract OVR is ERC721Creator {
    constructor() ERC721Creator("Manic Overgrowth", "OVR") {}
}