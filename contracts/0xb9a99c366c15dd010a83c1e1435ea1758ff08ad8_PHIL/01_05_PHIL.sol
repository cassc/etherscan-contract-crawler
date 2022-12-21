// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Philosopher
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    The Philosopher is working...    //
//                                     //
//                                     //
/////////////////////////////////////////


contract PHIL is ERC721Creator {
    constructor() ERC721Creator("The Philosopher", "PHIL") {}
}