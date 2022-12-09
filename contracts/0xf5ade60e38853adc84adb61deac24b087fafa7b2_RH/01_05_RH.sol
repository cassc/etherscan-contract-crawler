// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    __________  ___ ___      //
//    \______   \/   |   \     //
//     |       _/    ~    \    //
//     |    |   \    Y    /    //
//     |____|_  /\___|_  /     //
//            \/       \/      //
//                             //
//                             //
/////////////////////////////////


contract RH is ERC721Creator {
    constructor() ERC721Creator("RH", "RH") {}
}