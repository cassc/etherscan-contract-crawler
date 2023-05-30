// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Storm
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    My digital works as a multidisciplinary artist    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract ST is ERC721Creator {
    constructor() ERC721Creator("Storm", "ST") {}
}