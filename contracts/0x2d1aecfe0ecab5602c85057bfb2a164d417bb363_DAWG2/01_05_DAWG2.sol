// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dawg in me lvl 2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    DAWG2///////    //
//                    //
//                    //
////////////////////////


contract DAWG2 is ERC1155Creator {
    constructor() ERC1155Creator("Dawg in me lvl 2", "DAWG2") {}
}