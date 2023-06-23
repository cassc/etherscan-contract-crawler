// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One Eyed
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ONE EYED    //
//                //
//                //
////////////////////


contract OED is ERC721Creator {
    constructor() ERC721Creator("One Eyed", "OED") {}
}