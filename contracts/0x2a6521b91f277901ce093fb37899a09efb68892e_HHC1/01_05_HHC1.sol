// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hirshcon 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    HIRSHCON 1    //
//                  //
//                  //
//////////////////////


contract HHC1 is ERC721Creator {
    constructor() ERC721Creator("Hirshcon 1", "HHC1") {}
}