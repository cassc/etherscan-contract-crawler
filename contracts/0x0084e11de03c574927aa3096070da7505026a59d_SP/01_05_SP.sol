// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shinobi Path
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    High Council    //
//                    //
//                    //
////////////////////////


contract SP is ERC1155Creator {
    constructor() ERC1155Creator("Shinobi Path", "SP") {}
}