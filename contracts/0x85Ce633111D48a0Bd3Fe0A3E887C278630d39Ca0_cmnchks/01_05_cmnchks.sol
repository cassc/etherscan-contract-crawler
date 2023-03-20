// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: commonchecks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    jack butler i love you    //
//                              //
//                              //
//////////////////////////////////


contract cmnchks is ERC1155Creator {
    constructor() ERC1155Creator("commonchecks", "cmnchks") {}
}