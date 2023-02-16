// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beverly Kills Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    Art Should Comfort The Disturbed, And Disturb The Comfortable     //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract BKE is ERC1155Creator {
    constructor() ERC1155Creator("Beverly Kills Editions", "BKE") {}
}