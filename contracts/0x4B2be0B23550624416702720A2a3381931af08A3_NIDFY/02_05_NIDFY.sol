// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Non-identify
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Cri cri cri in life    //
//                           //
//                           //
///////////////////////////////


contract NIDFY is ERC721Creator {
    constructor() ERC721Creator("Non-identify", "NIDFY") {}
}