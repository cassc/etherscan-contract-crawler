// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BRuline
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     ___   ___   _     _     _   _      ____     //
//    | |_) | |_) | | | | |   | | | |\ | | |_      //
//    |_|_) |_| \ \_\_/ |_|__ |_| |_| \| |_|__     //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract BRULINE is ERC1155Creator {
    constructor() ERC1155Creator("BRuline", "BRULINE") {}
}