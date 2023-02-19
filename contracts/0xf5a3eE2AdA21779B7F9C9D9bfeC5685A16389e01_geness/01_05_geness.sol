// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    cool beans    //
//                  //
//                  //
//////////////////////


contract geness is ERC1155Creator {
    constructor() ERC1155Creator("genesis", "geness") {}
}