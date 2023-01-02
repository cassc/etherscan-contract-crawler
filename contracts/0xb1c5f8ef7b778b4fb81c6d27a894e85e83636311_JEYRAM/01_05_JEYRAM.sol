// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Journey by JeyRam
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Lets go on a journey!    //
//                             //
//                             //
/////////////////////////////////


contract JEYRAM is ERC721Creator {
    constructor() ERC721Creator("Journey by JeyRam", "JEYRAM") {}
}