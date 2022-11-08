// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YEYM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Yaeyama,Okinawa,Japan    //
//                             //
//                             //
/////////////////////////////////


contract YEYM is ERC721Creator {
    constructor() ERC721Creator("YEYM", "YEYM") {}
}