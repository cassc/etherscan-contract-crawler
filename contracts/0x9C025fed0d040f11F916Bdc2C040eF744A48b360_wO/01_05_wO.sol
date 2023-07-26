// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WandiObey
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    WandiObey    //
//                 //
//                 //
/////////////////////


contract wO is ERC1155Creator {
    constructor() ERC1155Creator("WandiObey", "wO") {}
}