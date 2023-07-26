// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lake House
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    My digital works as a multidisciplinary artist    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract LH is ERC721Creator {
    constructor() ERC721Creator("Lake House", "LH") {}
}