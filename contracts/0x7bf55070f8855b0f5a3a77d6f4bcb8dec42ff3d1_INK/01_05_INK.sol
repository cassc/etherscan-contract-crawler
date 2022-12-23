// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto Inkers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    Crypto Inkers is a NFT collection for who loves tattoo, geometry and technology    //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract INK is ERC721Creator {
    constructor() ERC721Creator("Crypto Inkers", "INK") {}
}