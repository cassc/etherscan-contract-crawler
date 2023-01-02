// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Lovepreet
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    2023    //
//            //
//            //
////////////////


contract EBL is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Lovepreet", "EBL") {}
}