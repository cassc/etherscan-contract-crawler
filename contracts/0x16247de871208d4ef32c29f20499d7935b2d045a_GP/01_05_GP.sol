// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pontes Animation
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    My digital works as a multidisciplinary artist    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract GP is ERC721Creator {
    constructor() ERC721Creator("Pontes Animation", "GP") {}
}