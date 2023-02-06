// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOAD CHECK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    jack butcher got me INSPIRED    //
//                                    //
//                                    //
////////////////////////////////////////


contract bpp is ERC1155Creator {
    constructor() ERC1155Creator("TOAD CHECK", "bpp") {}
}