// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ClosedEdition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    This is a closed edition.    //
//                                 //
//                                 //
/////////////////////////////////////


contract CE is ERC1155Creator {
    constructor() ERC1155Creator("ClosedEdition", "CE") {}
}