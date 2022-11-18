// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alpha Drops
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    https://www.alphadrops.net    //
//                                  //
//                                  //
//////////////////////////////////////


contract ALPHA is ERC721Creator {
    constructor() ERC721Creator("Alpha Drops", "ALPHA") {}
}