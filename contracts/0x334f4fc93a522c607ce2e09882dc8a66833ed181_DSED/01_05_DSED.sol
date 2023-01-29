// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Donut Stand Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Donut Stand Editions    //
//                            //
//                            //
////////////////////////////////


contract DSED is ERC1155Creator {
    constructor() ERC1155Creator("Donut Stand Editions", "DSED") {}
}