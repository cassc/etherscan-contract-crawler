// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MY PET HOOLIGAN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    AMGI    //
//            //
//            //
////////////////


contract MPH is ERC721Creator {
    constructor() ERC721Creator("MY PET HOOLIGAN", "MPH") {}
}