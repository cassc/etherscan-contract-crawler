// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A New Day
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    Supporting New York Cares and Stand With Students    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract AND is ERC1155Creator {
    constructor() ERC1155Creator("A New Day", "AND") {}
}