// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SW
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    SW    //
//          //
//          //
//////////////


contract SWC is ERC721Creator {
    constructor() ERC721Creator("SW", "SWC") {}
}