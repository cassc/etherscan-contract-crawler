// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Patience
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ..........Patience..........    //
//                                    //
//                                    //
////////////////////////////////////////


contract PAT1 is ERC1155Creator {
    constructor() ERC1155Creator("Patience", "PAT1") {}
}