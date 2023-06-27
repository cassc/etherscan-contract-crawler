// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: after thoughts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    💀    //
//          //
//          //
//////////////


contract AT is ERC721Creator {
    constructor() ERC721Creator("after thoughts", "AT") {}
}