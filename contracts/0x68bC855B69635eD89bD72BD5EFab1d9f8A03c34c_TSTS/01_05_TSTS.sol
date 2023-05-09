// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    test1155    //
//                //
//                //
////////////////////


contract TSTS is ERC1155Creator {
    constructor() ERC1155Creator("test1155", "TSTS") {}
}