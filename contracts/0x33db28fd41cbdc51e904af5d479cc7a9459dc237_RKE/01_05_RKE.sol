// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Roger Kilimanjaro Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     © Roger Kilimanjaro - Editions    //
//                                       //
//                                       //
///////////////////////////////////////////


contract RKE is ERC1155Creator {
    constructor() ERC1155Creator("Roger Kilimanjaro Editions", "RKE") {}
}