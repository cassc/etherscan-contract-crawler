// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Summercat_A
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    summercat              //
//                           //
//    twitter @_summercat    //
//                           //
//                           //
///////////////////////////////


contract SMC1 is ERC721Creator {
    constructor() ERC721Creator("Summercat_A", "SMC1") {}
}