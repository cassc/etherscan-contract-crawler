// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Art by Solemn    //
//                     //
//                     //
/////////////////////////


contract RFLCTS is ERC721Creator {
    constructor() ERC721Creator("Reflections", "RFLCTS") {}
}