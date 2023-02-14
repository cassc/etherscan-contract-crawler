// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I am a good trader - RC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    RC - g0d like    //
//                     //
//                     //
/////////////////////////


contract g0d is ERC721Creator {
    constructor() ERC721Creator("I am a good trader - RC", "g0d") {}
}