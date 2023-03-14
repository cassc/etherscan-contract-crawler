// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Airdrop for holders    //
//                           //
//                           //
///////////////////////////////


contract PEPES is ERC721Creator {
    constructor() ERC721Creator("PEPES", "PEPES") {}
}