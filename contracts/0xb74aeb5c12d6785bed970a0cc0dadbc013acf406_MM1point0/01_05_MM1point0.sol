// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mongo Manifold 1.0
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    astronaut | NFT artist | author | co-founder, OBEY    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract MM1point0 is ERC721Creator {
    constructor() ERC721Creator("Mongo Manifold 1.0", "MM1point0") {}
}