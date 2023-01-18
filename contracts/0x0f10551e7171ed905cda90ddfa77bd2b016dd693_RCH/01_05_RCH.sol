// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by RECHAO.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    @1RECHAO    //
//                //
//                //
////////////////////


contract RCH is ERC1155Creator {
    constructor() ERC1155Creator("Editions by RECHAO.", "RCH") {}
}