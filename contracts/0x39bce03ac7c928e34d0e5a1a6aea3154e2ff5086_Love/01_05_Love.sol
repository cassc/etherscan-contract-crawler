// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Endless
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    Loverboy    //
//                //
//                //
////////////////////


contract Love is ERC1155Creator {
    constructor() ERC1155Creator("Endless", "Love") {}
}