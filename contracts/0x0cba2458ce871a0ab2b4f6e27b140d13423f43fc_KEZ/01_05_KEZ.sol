// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kennetheze 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    A collection of my emotions brought to life    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract KEZ is ERC721Creator {
    constructor() ERC721Creator("kennetheze 1/1", "KEZ") {}
}