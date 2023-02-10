// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beverly Kills
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    Art Should Comfort The Disturbed, And Disturb The Comfortable     //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract BK is ERC721Creator {
    constructor() ERC721Creator("Beverly Kills", "BK") {}
}