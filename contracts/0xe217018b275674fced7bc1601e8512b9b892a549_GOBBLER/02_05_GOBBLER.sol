// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art GobbIers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ART GOBBLERS    //
//                    //
//                    //
////////////////////////


contract GOBBLER is ERC721Creator {
    constructor() ERC721Creator("Art GobbIers", "GOBBLER") {}
}