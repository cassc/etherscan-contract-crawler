// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cryptoskunks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    .__                         //
//    |  |__   _____   _____      //
//    |  |  \ /     \ /     \     //
//    |   Y  \  Y Y  \  Y Y  \    //
//    |___|  /__|_|  /__|_|  /    //
//         \/      \/      \/     //
//                                //
//                                //
////////////////////////////////////


contract skunk is ERC721Creator {
    constructor() ERC721Creator("cryptoskunks", "skunk") {}
}