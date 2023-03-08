// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: oclockEdition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    o'ClockEdition    //
//                      //
//                      //
//////////////////////////


contract CLOCK is ERC721Creator {
    constructor() ERC721Creator("oclockEdition", "CLOCK") {}
}