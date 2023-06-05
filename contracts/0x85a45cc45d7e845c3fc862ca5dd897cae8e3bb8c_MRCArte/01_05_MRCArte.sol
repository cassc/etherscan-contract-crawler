// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MRC Arte
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Arte is art    //
//                   //
//                   //
///////////////////////


contract MRCArte is ERC1155Creator {
    constructor() ERC1155Creator("MRC Arte", "MRCArte") {}
}