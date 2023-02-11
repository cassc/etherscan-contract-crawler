// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mobaskol
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :D    //
//          //
//          //
//////////////


contract Otter is ERC721Creator {
    constructor() ERC721Creator("mobaskol", "Otter") {}
}