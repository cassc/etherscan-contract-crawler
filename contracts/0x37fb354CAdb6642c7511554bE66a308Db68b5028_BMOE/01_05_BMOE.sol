// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BTC WAIFU
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    BTC WAIFU CROSS CHAIN    //
//                             //
//                             //
/////////////////////////////////


contract BMOE is ERC721Creator {
    constructor() ERC721Creator("BTC WAIFU", "BMOE") {}
}