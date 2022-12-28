// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Splurge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    The Splurge    //
//                   //
//                   //
///////////////////////


contract Splurge is ERC721Creator {
    constructor() ERC721Creator("The Splurge", "Splurge") {}
}