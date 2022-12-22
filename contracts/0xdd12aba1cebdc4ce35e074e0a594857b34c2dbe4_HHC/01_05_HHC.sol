// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Holiday Card
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Happy Holidays ! from AOM    //
//                                 //
//                                 //
/////////////////////////////////////


contract HHC is ERC721Creator {
    constructor() ERC721Creator("Holiday Card", "HHC") {}
}