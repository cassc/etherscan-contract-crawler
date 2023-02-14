// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test NIC Transfer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ------- RUN IT ---------    //
//                                //
//                                //
////////////////////////////////////


contract TNT is ERC721Creator {
    constructor() ERC721Creator("Test NIC Transfer", "TNT") {}
}