// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Last Goodbyes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    got no time for this ascii mark thing     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract KLG is ERC721Creator {
    constructor() ERC721Creator("Last Goodbyes", "KLG") {}
}