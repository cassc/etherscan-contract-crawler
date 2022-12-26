// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sweet Chaos
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    Collection of bright and sweet girls    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract SWC is ERC1155Creator {
    constructor() ERC1155Creator("Sweet Chaos", "SWC") {}
}