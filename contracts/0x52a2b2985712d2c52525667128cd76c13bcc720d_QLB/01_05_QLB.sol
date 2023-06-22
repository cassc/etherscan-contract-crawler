// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Quins Late Bday gif
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    QuinBrick    //
//                 //
//                 //
/////////////////////


contract QLB is ERC721Creator {
    constructor() ERC721Creator("Quins Late Bday gif", "QLB") {}
}