// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Summercat_C
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Summercat              //
//                           //
//    Twitter @_summercat    //
//                           //
//                           //
///////////////////////////////


contract SMC3 is ERC721Creator {
    constructor() ERC721Creator("Summercat_C", "SMC3") {}
}