// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yadokari
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    I hope it will reach many people.    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract YADOKARI is ERC721Creator {
    constructor() ERC721Creator("yadokari", "YADOKARI") {}
}