// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rainbowmaterial Unagi ETH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    rainbowmaterial collaboration with Unagi ETH chain    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract rUETH is ERC721Creator {
    constructor() ERC721Creator("rainbowmaterial Unagi ETH", "rUETH") {}
}