// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kennetheze 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    eze was here and he loves you.    //
//                                      //
//                                      //
//////////////////////////////////////////


contract EZE is ERC721Creator {
    constructor() ERC721Creator("kennetheze 1/1", "EZE") {}
}