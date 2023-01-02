// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SH1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    S                                        H                                        1    //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract SH1 is ERC721Creator {
    constructor() ERC721Creator("SH1", "SH1") {}
}