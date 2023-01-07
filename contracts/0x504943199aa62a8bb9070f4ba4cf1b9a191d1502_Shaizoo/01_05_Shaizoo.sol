// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shaizoo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//    I'm Shaizoo! I'm an avid learner and lover of all things tech, design, and creativity.    //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract Shaizoo is ERC721Creator {
    constructor() ERC721Creator("Shaizoo", "Shaizoo") {}
}