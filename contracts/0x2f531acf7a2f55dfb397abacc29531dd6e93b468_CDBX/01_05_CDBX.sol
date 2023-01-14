// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTODUBX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    CRYPTODUBX    //
//                  //
//                  //
//////////////////////


contract CDBX is ERC1155Creator {
    constructor() ERC1155Creator("CRYPTODUBX", "CDBX") {}
}