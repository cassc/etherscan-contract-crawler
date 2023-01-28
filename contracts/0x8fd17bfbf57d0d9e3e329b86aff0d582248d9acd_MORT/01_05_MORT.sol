// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COMPROMISED
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    You have been compromised    //
//                                 //
//                                 //
/////////////////////////////////////


contract MORT is ERC1155Creator {
    constructor() ERC1155Creator("COMPROMISED", "MORT") {}
}