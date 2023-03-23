// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MJRM Contract 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    MJRM    //
//            //
//            //
////////////////


contract MJRM1 is ERC721Creator {
    constructor() ERC721Creator("MJRM Contract 1", "MJRM1") {}
}