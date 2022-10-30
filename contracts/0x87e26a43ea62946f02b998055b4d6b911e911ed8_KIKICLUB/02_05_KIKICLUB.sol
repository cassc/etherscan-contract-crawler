// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE KIKI CLUB
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    THE KIKI CLUB    //
//                     //
//                     //
/////////////////////////


contract KIKICLUB is ERC721Creator {
    constructor() ERC721Creator("THE KIKI CLUB", "KIKICLUB") {}
}