// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RCotter
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    RCot    //
//            //
//            //
////////////////


contract RCot is ERC721Creator {
    constructor() ERC721Creator("RCotter", "RCot") {}
}