// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solemn
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Art by Solemn    //
//                     //
//                     //
/////////////////////////


contract SolemnS is ERC1155Creator {
    constructor() ERC1155Creator("Solemn", "SolemnS") {}
}