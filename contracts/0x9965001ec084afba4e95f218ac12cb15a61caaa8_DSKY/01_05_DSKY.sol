// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DREAM CITYSCRAPERS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    DSKY    //
//            //
//            //
////////////////


contract DSKY is ERC721Creator {
    constructor() ERC721Creator("DREAM CITYSCRAPERS", "DSKY") {}
}