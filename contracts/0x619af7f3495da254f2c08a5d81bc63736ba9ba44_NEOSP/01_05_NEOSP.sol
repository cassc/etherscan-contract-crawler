// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEO's Special
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    This is an illustration that expresses our gratitude. (Neo-chan ver.)    //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract NEOSP is ERC1155Creator {
    constructor() ERC1155Creator("NEO's Special", "NEOSP") {}
}