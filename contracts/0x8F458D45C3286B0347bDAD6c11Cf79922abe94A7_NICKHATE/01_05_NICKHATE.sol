// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nick Hates Woman
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    Nick hates woman, quoted on nifty discord 14.02.23    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract NICKHATE is ERC721Creator {
    constructor() ERC721Creator("Nick Hates Woman", "NICKHATE") {}
}