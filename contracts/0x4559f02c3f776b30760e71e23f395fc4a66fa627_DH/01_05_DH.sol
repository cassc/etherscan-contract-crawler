// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Delivering Happiness
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ┗|´・_●・|┛=3    //
//                   //
//                   //
///////////////////////


contract DH is ERC721Creator {
    constructor() ERC721Creator("Delivering Happiness", "DH") {}
}