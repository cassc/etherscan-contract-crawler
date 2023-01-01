// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Lights
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Art by Leni Amber    //
//                         //
//                         //
/////////////////////////////


contract RDLGTS is ERC1155Creator {
    constructor() ERC1155Creator("Red Lights", "RDLGTS") {}
}