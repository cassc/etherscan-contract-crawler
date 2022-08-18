// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Twitch Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    BADFROOT    //
//                //
//                //
////////////////////


contract TTC is ERC721Creator {
    constructor() ERC721Creator("The Twitch Collection", "TTC") {}
}