// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: luxcryptoart
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    For me creativity is nothing but a mind set free.    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract LCA is ERC721Creator {
    constructor() ERC721Creator("luxcryptoart", "LCA") {}
}