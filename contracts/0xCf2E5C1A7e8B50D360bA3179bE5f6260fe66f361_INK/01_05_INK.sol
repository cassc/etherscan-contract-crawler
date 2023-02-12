// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: innsbruck
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    innsbruck    //
//                 //
//                 //
/////////////////////


contract INK is ERC721Creator {
    constructor() ERC721Creator("innsbruck", "INK") {}
}