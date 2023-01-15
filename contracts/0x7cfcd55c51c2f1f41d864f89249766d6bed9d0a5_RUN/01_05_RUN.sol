// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bull Run Pool Party
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Bull Run    //
//                //
//                //
////////////////////


contract RUN is ERC721Creator {
    constructor() ERC721Creator("Bull Run Pool Party", "RUN") {}
}