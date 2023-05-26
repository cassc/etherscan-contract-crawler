// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Self-Seeded
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Self-Seeded by Renee Campbell    //
//                                     //
//                                     //
/////////////////////////////////////////


contract SSeed is ERC721Creator {
    constructor() ERC721Creator("Self-Seeded", "SSeed") {}
}