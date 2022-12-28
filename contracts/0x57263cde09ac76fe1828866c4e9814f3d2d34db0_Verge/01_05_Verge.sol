// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Verge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    The Verge    //
//                 //
//                 //
/////////////////////


contract Verge is ERC721Creator {
    constructor() ERC721Creator("The Verge", "Verge") {}
}