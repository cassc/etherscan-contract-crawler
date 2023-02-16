// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moose Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Moose Checks    //
//                    //
//                    //
////////////////////////


contract MC is ERC1155Creator {
    constructor() ERC1155Creator("Moose Checks", "MC") {}
}