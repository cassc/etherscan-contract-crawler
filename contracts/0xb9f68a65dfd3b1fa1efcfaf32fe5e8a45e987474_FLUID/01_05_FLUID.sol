// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fluidity by Dominique Varendorff
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//      _                          //
//     |_ |     o  _| o _|_        //
//     |  | |_| | (_| |  |_ \/     //
//                          /      //
//                                 //
//                                 //
/////////////////////////////////////


contract FLUID is ERC721Creator {
    constructor() ERC721Creator("Fluidity by Dominique Varendorff", "FLUID") {}
}