// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BITCOINORB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    xoxox    //
//             //
//             //
/////////////////


contract BTCORB is ERC721Creator {
    constructor() ERC721Creator("BITCOINORB", "BTCORB") {}
}