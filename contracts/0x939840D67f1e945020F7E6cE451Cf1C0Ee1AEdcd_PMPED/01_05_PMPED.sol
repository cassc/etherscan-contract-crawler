// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PMP Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    PMP Limited Editions    //
//                            //
//                            //
////////////////////////////////


contract PMPED is ERC1155Creator {
    constructor() ERC1155Creator("PMP Editions", "PMPED") {}
}