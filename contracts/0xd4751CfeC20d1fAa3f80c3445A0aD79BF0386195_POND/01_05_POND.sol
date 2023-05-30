// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pondering Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Pondering Edition    //
//                         //
//                         //
/////////////////////////////


contract POND is ERC1155Creator {
    constructor() ERC1155Creator("Pondering Edition", "POND") {}
}