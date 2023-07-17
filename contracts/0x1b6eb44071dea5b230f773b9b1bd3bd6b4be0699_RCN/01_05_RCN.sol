// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raccoon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Raccoon!    //
//                //
//                //
////////////////////


contract RCN is ERC721Creator {
    constructor() ERC721Creator("Raccoon", "RCN") {}
}