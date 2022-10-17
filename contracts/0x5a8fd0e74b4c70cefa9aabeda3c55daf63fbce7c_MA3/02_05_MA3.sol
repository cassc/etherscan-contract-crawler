// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My art 3
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    My first gen art project    //
//                                //
//                                //
////////////////////////////////////


contract MA3 is ERC721Creator {
    constructor() ERC721Creator("My art 3", "MA3") {}
}