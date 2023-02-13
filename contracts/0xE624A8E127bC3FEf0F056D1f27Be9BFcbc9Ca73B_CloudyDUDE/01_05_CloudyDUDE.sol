// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MR.DOODLE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//    Introduction of my first collection ever that is on opensea                                                    //
//                                                                                                                   //
//    Called "La tête dans les nuages" which mean head in the clouds.                                                //
//                                                                                                                   //
//    A man wihtout his head, with a cloud on the top of it, with different seasons representing different moods.    //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CloudyDUDE is ERC721Creator {
    constructor() ERC721Creator("MR.DOODLE", "CloudyDUDE") {}
}