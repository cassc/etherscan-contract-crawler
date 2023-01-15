// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Limitless By Design
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ^L^I^M^I^T^L^E^S^S^    //
//                           //
//                           //
///////////////////////////////


contract LBD is ERC1155Creator {
    constructor() ERC1155Creator("Limitless By Design", "LBD") {}
}