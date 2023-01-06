// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cyborg Wolves
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Cyborg Wolves    //
//                     //
//                     //
/////////////////////////


contract CBWolves is ERC1155Creator {
    constructor() ERC1155Creator("Cyborg Wolves", "CBWolves") {}
}