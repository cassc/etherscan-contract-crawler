// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: infernoa
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    infernoa    //
//                //
//                //
////////////////////


contract infernoa is ERC1155Creator {
    constructor() ERC1155Creator("infernoa", "infernoa") {}
}