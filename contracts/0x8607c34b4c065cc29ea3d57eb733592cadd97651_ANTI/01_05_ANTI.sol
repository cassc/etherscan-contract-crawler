// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meta Antiheroes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Meta Antiheroes Gen. 1    //
//                              //
//                              //
//////////////////////////////////


contract ANTI is ERC721Creator {
    constructor() ERC721Creator("Meta Antiheroes", "ANTI") {}
}