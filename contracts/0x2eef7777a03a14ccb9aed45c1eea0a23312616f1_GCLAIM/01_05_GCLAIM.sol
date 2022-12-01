// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gclaim
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    The contract made by Raf Grassetti - Claim Projects    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract GCLAIM is ERC1155Creator {
    constructor() ERC1155Creator("gclaim", "GCLAIM") {}
}