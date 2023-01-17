// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CollagenoRandom
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    /    //
//         //
//         //
/////////////


contract CLLGNRNDM is ERC721Creator {
    constructor() ERC721Creator("CollagenoRandom", "CLLGNRNDM") {}
}