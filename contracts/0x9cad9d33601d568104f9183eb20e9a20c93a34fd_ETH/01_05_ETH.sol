// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: T Demons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    0x51a1f8A5655d4107B19C93FA862aA76338eE4326    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("T Demons", "ETH") {}
}