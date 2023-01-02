// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Summercat_D
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Summercat              //
//                           //
//    Twitter @_summercat    //
//                           //
//                           //
///////////////////////////////


contract SMC4 is ERC1155Creator {
    constructor() ERC1155Creator("Summercat_D", "SMC4") {}
}