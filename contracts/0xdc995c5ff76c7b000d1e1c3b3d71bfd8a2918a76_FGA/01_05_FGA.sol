// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FightGirlsAI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    Please love these cute fighters imagined by AI!    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract FGA is ERC721Creator {
    constructor() ERC721Creator("FightGirlsAI", "FGA") {}
}