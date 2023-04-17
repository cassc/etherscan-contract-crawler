// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE MRC ARTE 1/1 COLLECTION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    ||||||||||||||||    //
//    ||  MRC_ARTE  ||    //
//    ||||||||||||||||    //
//    ||||||||||||||||    //
//    || THE        ||    //
//    || COLLECTION ||    //
//    ||||||||||||||||    //
//                        //
//                        //
////////////////////////////


contract MRC is ERC721Creator {
    constructor() ERC721Creator("THE MRC ARTE 1/1 COLLECTION", "MRC") {}
}