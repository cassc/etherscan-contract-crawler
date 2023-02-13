// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Liberation
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Call me Czy Just Czy    //
//                            //
//                            //
////////////////////////////////


contract Liber is ERC721Creator {
    constructor() ERC721Creator("Liberation", "Liber") {}
}