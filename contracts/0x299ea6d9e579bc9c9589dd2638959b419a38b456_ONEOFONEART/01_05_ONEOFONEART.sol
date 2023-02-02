// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stef's 1/1's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//     :::     === :::      :::====  :::====  :::====    //
//     :::    ===  :::      :::  === :::  === :::====    //
//     ===   ===   ===      ======== =======    ===      //
//     ===  ===    ===      ===  === === ===    ===      //
//     === ===     ===      ===  === ===  ===   ===      //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract ONEOFONEART is ERC721Creator {
    constructor() ERC721Creator("Stef's 1/1's", "ONEOFONEART") {}
}