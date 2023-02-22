// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Msince85
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Msince85    //
//                //
//                //
////////////////////


contract Ms85 is ERC721Creator {
    constructor() ERC721Creator("Msince85", "Ms85") {}
}