// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soul Walker
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Soul Blues    //
//                  //
//                  //
//////////////////////


contract SOUL is ERC1155Creator {
    constructor() ERC1155Creator("Soul Walker", "SOUL") {}
}