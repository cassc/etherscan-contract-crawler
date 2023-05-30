// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Price Is Almost Right
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    The Price Is Almost Right    //
//                                 //
//                                 //
/////////////////////////////////////


contract TPIAR is ERC721Creator {
    constructor() ERC721Creator("The Price Is Almost Right", "TPIAR") {}
}