// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soul Snatcher
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Soul Snatcher    //
//                     //
//                     //
/////////////////////////


contract SS is ERC1155Creator {
    constructor() ERC1155Creator("Soul Snatcher", "SS") {}
}