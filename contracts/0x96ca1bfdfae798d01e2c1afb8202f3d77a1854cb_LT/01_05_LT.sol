// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Legacy Tape
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     +-+-+-+-+-+-+ +-+-+-+-+    //
//     |L|e|g|a|c|y| |T|a|p|e|    //
//     +-+-+-+-+-+-+ +-+-+-+-+    //
//                                //
//                                //
////////////////////////////////////


contract LT is ERC1155Creator {
    constructor() ERC1155Creator("Legacy Tape", "LT") {}
}