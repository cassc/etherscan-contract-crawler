// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blockchain Verify Check
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Blockchain Verify Check     //
//                                //
//                                //
////////////////////////////////////


contract BCVC is ERC1155Creator {
    constructor() ERC1155Creator("Blockchain Verify Check", "BCVC") {}
}