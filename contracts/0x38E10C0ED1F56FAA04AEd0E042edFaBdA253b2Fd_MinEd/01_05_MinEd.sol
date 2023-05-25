// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimations Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Minimations Editions    //
//                            //
//                            //
////////////////////////////////


contract MinEd is ERC1155Creator {
    constructor() ERC1155Creator("Minimations Editions", "MinEd") {}
}