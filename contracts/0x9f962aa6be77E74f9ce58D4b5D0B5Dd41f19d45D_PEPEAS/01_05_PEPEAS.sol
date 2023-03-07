// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE_ASCII
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    PEPE_ASCII    //
//                  //
//                  //
//////////////////////


contract PEPEAS is ERC1155Creator {
    constructor() ERC1155Creator("PEPE_ASCII", "PEPEAS") {}
}