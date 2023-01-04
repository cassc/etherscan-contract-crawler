// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BHARE ORIGINALS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    1/1s created by Bhare.    //
//                              //
//                              //
//////////////////////////////////


contract BORIG is ERC721Creator {
    constructor() ERC721Creator("BHARE ORIGINALS", "BORIG") {}
}