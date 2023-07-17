// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Breaking Bad
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    come on Jesse, we have work to do.    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract BBD is ERC721Creator {
    constructor() ERC721Creator("Breaking Bad", "BBD") {}
}