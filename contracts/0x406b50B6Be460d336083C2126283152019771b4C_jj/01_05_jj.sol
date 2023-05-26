// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: juneyjune
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Art Art Art    //
//                   //
//                   //
///////////////////////


contract jj is ERC721Creator {
    constructor() ERC721Creator("juneyjune", "jj") {}
}