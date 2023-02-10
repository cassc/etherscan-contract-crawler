// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OrdinalApepunks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    OrdinalApepunks    //
//                       //
//                       //
///////////////////////////


contract OAP is ERC1155Creator {
    constructor() ERC1155Creator("OrdinalApepunks", "OAP") {}
}