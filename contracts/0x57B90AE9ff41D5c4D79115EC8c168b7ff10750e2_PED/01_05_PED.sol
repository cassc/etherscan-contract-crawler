// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepEditions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    // may or may not be culturally relevant.    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract PED is ERC1155Creator {
    constructor() ERC1155Creator("PepEditions", "PED") {}
}