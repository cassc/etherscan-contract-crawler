// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2026 College Fund
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    nurse college fund for my girl    //
//                                      //
//                                      //
//////////////////////////////////////////


contract cf is ERC721Creator {
    constructor() ERC721Creator("2026 College Fund", "cf") {}
}