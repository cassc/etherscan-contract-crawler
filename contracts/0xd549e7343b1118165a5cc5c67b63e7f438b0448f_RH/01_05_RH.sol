// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RH
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract RH is ERC1155Creator {
    constructor() ERC1155Creator("RH", "RH") {}
}