// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal Apes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    OrdinalApes    //
//                   //
//                   //
///////////////////////


contract OA is ERC1155Creator {
    constructor() ERC1155Creator("Ordinal Apes", "OA") {}
}