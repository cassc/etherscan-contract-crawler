// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hope
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    lifes little Beauties...    //
//                                //
//                                //
////////////////////////////////////


contract LRJ is ERC721Creator {
    constructor() ERC721Creator("Hope", "LRJ") {}
}