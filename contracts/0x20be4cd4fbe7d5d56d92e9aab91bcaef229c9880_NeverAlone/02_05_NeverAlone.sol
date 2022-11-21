// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Never Alone Genesis Series #1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Never Alone Genesis Series     //
//    Collection #1                  //
//                                   //
//                                   //
///////////////////////////////////////


contract NeverAlone is ERC721Creator {
    constructor() ERC721Creator("Never Alone Genesis Series #1", "NeverAlone") {}
}