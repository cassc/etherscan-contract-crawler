// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: APE CHECKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    APECHECKS - INSPIRED BY CHECKS VV      //
//                                           //
//                                           //
///////////////////////////////////////////////


contract APECHECKS is ERC721Creator {
    constructor() ERC721Creator("APE CHECKS", "APECHECKS") {}
}