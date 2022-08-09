// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Perpetual
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//        ♺        //
//                 //
//    Perpetual    //
//    0xG          //
//                 //
//                 //
/////////////////////


contract PPTVL is ERC721Creator {
    constructor() ERC721Creator("Perpetual", "PPTVL") {}
}