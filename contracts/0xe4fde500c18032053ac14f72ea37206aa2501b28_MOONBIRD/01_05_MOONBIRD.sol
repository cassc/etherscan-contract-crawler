// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moonbirds Airdrops
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Moonbird    //
//                //
//                //
////////////////////


contract MOONBIRD is ERC721Creator {
    constructor() ERC721Creator("Moonbirds Airdrops", "MOONBIRD") {}
}