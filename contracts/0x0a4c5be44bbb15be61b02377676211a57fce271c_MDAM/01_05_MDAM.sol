// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAKE-DO AND MEME
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    ██████  ███████  ██████   █████  ███    ██       //
//    ██   ██ ██      ██       ██   ██ ████   ██       //
//    ██████  █████   ██   ███ ███████ ██ ██  ██       //
//    ██   ██ ██      ██    ██ ██   ██ ██  ██ ██       //
//    ██   ██ ███████  ██████  ██   ██ ██   ████ <3    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract MDAM is ERC1155Creator {
    constructor() ERC1155Creator("MAKE-DO AND MEME", "MDAM") {}
}