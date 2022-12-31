// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Leap
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    .____                             //
//    |    |    ____ _____  ______      //
//    |    |  _/ __ \\__  \ \____ \     //
//    |    |__\  ___/ / __ \|  |_> >    //
//    |_______ \___  >____  /   __/     //
//            \/   \/     \/|__|        //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract Leap is ERC721Creator {
    constructor() ERC721Creator("Leap", "Leap") {}
}