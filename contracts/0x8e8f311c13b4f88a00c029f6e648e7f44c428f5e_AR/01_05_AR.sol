// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Assorted Rabbits
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ₍ᐢ..ᐢ₎=3    //
//                //
//                //
////////////////////


contract AR is ERC721Creator {
    constructor() ERC721Creator("Assorted Rabbits", "AR") {}
}