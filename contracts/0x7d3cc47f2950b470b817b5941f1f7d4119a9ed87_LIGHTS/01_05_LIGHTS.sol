// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost Among The Lights
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


contract LIGHTS is ERC721Creator {
    constructor() ERC721Creator("Lost Among The Lights", "LIGHTS") {}
}