// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GUMIGOS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    □────────────────□────────────────□    //
//    │                                 │    //
//    │                                 │    //
//    □            'GUMIGOS'            □    //
//    │                                 │    //
//    │                                 │    //
//    □────────────────□────────────────□    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract KAMT is ERC1155Creator {
    constructor() ERC1155Creator("GUMIGOS", "KAMT") {}
}