// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRAITOR
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    Burn 4 'TRAITOR' to redeem 1 'Modern Art Beast'    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract TRT is ERC1155Creator {
    constructor() ERC1155Creator("TRAITOR", "TRT") {}
}