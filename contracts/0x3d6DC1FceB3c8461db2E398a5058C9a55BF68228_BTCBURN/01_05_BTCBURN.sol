// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BTC BURN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    BURN FOR ORDINAL    //
//                        //
//                        //
////////////////////////////


contract BTCBURN is ERC721Creator {
    constructor() ERC721Creator("BTC BURN", "BTCBURN") {}
}