// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hot Wings Collective
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    //HOT WINGS COLLECTIVE//    //
//                                //
//                                //
////////////////////////////////////


contract HWC is ERC721Creator {
    constructor() ERC721Creator("Hot Wings Collective", "HWC") {}
}