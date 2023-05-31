// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Down Bad
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    DOWN BAD    //
//                //
//                //
////////////////////


contract DNBD is ERC1155Creator {
    constructor() ERC1155Creator("Down Bad", "DNBD") {}
}