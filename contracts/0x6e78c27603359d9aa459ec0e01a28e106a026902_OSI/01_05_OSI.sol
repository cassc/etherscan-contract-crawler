// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: osushi-san illustration
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    osushi-san    //
//                  //
//                  //
//////////////////////


contract OSI is ERC721Creator {
    constructor() ERC721Creator("osushi-san illustration", "OSI") {}
}