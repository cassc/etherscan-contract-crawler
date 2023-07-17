// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Don't Give A Fuck
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    don't give a fuck enough to create ascii art    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract DGAF is ERC721Creator {
    constructor() ERC721Creator("Don't Give A Fuck", "DGAF") {}
}