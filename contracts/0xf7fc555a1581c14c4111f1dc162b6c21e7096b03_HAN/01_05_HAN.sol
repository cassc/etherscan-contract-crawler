// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HERE & NOW
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    HERE & NOW    //
//                  //
//                  //
//////////////////////


contract HAN is ERC721Creator {
    constructor() ERC721Creator("HERE & NOW", "HAN") {}
}