// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOAZ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Art bY Boaz    //
//    x @wrkbzs !    //
//                   //
//                   //
///////////////////////


contract bz is ERC1155Creator {
    constructor() ERC1155Creator("BOAZ", "bz") {}
}