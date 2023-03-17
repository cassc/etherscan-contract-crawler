// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: floor it and gtfo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    Floor it and gtfo, there is nothing more to say here...    //
//    art by NightOwlBirdman and CheddaaBob                      //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract gtfo is ERC721Creator {
    constructor() ERC721Creator("floor it and gtfo", "gtfo") {}
}