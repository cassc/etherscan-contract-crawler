// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mad Void Pilots
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    The Mad Void Pilots are pilots who have lost their minds while overtraveling in Void Space.    //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract MVP is ERC1155Creator {
    constructor() ERC1155Creator("Mad Void Pilots", "MVP") {}
}