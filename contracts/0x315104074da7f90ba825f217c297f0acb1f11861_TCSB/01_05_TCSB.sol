// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Chinese Spy Balloon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Fly, fly, fly away!    //
//                           //
//                           //
///////////////////////////////


contract TCSB is ERC1155Creator {
    constructor() ERC1155Creator("The Chinese Spy Balloon", "TCSB") {}
}