// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RarePepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    RarePepe    //
//                //
//                //
////////////////////


contract RRPP is ERC1155Creator {
    constructor() ERC1155Creator("RarePepe", "RRPP") {}
}