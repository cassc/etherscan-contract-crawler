// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: METASPACE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    METASPACE    //
//                 //
//                 //
/////////////////////


contract METASPACE is ERC1155Creator {
    constructor() ERC1155Creator("METASPACE", "METASPACE") {}
}