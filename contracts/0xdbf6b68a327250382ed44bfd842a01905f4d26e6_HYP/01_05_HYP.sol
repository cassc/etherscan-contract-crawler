// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HypeFactory
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    Are we all in this together? HypeorDie    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract HYP is ERC721Creator {
    constructor() ERC721Creator("HypeFactory", "HYP") {}
}