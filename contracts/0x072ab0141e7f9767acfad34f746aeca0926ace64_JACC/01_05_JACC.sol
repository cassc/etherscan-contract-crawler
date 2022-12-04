// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jacked Ape Contract Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Jacked Ape Contract Club    //
//                                //
//                                //
////////////////////////////////////


contract JACC is ERC721Creator {
    constructor() ERC721Creator("Jacked Ape Contract Club", "JACC") {}
}