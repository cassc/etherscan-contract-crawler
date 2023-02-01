// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: snake by dentist
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//    ©snake by dentist    //
//                         //
//                         //
//                         //
/////////////////////////////


contract sbd is ERC1155Creator {
    constructor() ERC1155Creator("snake by dentist", "sbd") {}
}