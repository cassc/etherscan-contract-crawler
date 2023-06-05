// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BK Giveaway
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    Art Should Comfort The Disturbed, And Disturb The Comfortable     //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract BKG is ERC1155Creator {
    constructor() ERC1155Creator("BK Giveaway", "BKG") {}
}