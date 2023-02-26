// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Encounters
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//     ___       __   __            ___  ___  __   __                      //
//    |__  |\ | /  ` /  \ |  | |\ |  |  |__  |__) /__`                     //
//    |___ | \| \__, \__/ \__/ | \|  |  |___ |  \ .__/                     //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract ENCTR is ERC721Creator {
    constructor() ERC721Creator("Encounters", "ENCTR") {}
}