// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MinCash Photography
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Photography by MinCash    //
//                              //
//                              //
//////////////////////////////////


contract MCASH is ERC1155Creator {
    constructor() ERC1155Creator("MinCash Photography", "MCASH") {}
}