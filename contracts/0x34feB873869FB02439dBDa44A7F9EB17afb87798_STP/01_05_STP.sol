// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: [SansToi] Prelude
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//    Every tale has its own beginnning... before the Witch, this story starts from her mother.    //
//                                                                                                 //
//    Prelude for [Sans Toi], an NFT Series from Nyaro / Saperlipopettec.                          //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract STP is ERC1155Creator {
    constructor() ERC1155Creator("[SansToi] Prelude", "STP") {}
}