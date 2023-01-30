// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sony Cybershot DSC-W1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    crunchcrunchcrunchcrunchcrunch    //
//    crunchcrunchcrunchcrunchcrunch    //
//    crunchcrunchcrunchcrunchcrunch    //
//    crunchcrunchcrunchcrunchcrunch    //
//    crunchcrunchcrunchcrunchcrunch    //
//                                      //
//                                      //
//////////////////////////////////////////


contract CYBERSHOT is ERC1155Creator {
    constructor() ERC1155Creator("Sony Cybershot DSC-W1", "CYBERSHOT") {}
}