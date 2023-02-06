// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mtn
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//      ^      //
//    /   \    //
//             //
//             //
/////////////////


contract MTN is ERC721Creator {
    constructor() ERC721Creator("mtn", "MTN") {}
}