// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alpha Crystal
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    ✧･ﾟ: * ✧･ﾟ:*     //
//    .・゜゜・            //
//    ｡･ﾟﾟ･            //
//                     //
//                     //
/////////////////////////


contract CRSTL is ERC1155Creator {
    constructor() ERC1155Creator("Alpha Crystal", "CRSTL") {}
}