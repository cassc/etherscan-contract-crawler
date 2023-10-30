// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Inner Worlds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    Abstract 1/1 art from my innermost feeling.    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SGIW is ERC721Creator {
    constructor() ERC721Creator("My Inner Worlds", "SGIW") {}
}