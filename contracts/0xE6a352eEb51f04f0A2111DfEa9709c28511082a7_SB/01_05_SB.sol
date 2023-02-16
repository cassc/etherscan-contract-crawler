// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUNSET
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    SB    //
//          //
//          //
//////////////


contract SB is ERC1155Creator {
    constructor() ERC1155Creator("SUNSET", "SB") {}
}