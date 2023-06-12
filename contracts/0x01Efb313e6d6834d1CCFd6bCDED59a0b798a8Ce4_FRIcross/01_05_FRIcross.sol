// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fridge's Crossover
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    a collection of my collaborations with other artists    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract FRIcross is ERC721Creator {
    constructor() ERC721Creator("Fridge's Crossover", "FRIcross") {}
}