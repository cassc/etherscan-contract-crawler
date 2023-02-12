// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moose Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Moose Checks    //
//                    //
//                    //
////////////////////////


contract MC is ERC721Creator {
    constructor() ERC721Creator("Moose Checks", "MC") {}
}