// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRIDFICTION
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    @gridfiction    //
//                    //
//                    //
////////////////////////


contract GRID is ERC721Creator {
    constructor() ERC721Creator("GRIDFICTION", "GRID") {}
}