// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shark DAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    SharkDAO ⌐◨-◨    //
//                     //
//                     //
/////////////////////////


contract SHARKDAO is ERC721Creator {
    constructor() ERC721Creator("Shark DAO", "SHARKDAO") {}
}