// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: it's time to stop
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    (======3    //
//                //
//                //
////////////////////


contract tts is ERC721Creator {
    constructor() ERC721Creator("it's time to stop", "tts") {}
}