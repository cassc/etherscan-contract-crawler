// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTGOD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    NFTGOD    //
//              //
//              //
//////////////////


contract JBNFTGOD is ERC721Creator {
    constructor() ERC721Creator("NFTGOD", "JBNFTGOD") {}
}