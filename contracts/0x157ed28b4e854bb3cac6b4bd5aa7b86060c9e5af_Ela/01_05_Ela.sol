// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: obsEssion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//     _______  _        _______     //
//    (  ____ \( \      (  ___  )    //
//    | (    \/| (      | (   ) |    //
//    | (__    | |      | (___) |    //
//    |  __)   | |      |  ___  |    //
//    | (      | |      | (   ) |    //
//    | (____/\| (____/\| )   ( |    //
//    (_______/(_______/|/     \|    //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract Ela is ERC721Creator {
    constructor() ERC721Creator("obsEssion", "Ela") {}
}