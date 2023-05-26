// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jokedao nfts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    lfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfjlfj    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract joke is ERC721Creator {
    constructor() ERC721Creator("jokedao nfts", "joke") {}
}