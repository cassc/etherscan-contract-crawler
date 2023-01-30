// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crown
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    My crown    //
//                //
//                //
////////////////////


contract crown is ERC1155Creator {
    constructor() ERC1155Creator("Crown", "crown") {}
}