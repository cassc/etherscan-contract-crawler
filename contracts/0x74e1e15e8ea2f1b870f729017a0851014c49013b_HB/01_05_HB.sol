// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Husky butthole
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    HB    //
//          //
//          //
//////////////


contract HB is ERC1155Creator {
    constructor() ERC1155Creator("Husky butthole", "HB") {}
}