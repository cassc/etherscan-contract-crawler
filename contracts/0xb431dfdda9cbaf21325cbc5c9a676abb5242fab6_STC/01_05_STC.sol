// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seize The Culture
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Lets Try this again....    //
//                               //
//                               //
///////////////////////////////////


contract STC is ERC1155Creator {
    constructor() ERC1155Creator("Seize The Culture", "STC") {}
}