// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Culture by Hash
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    ██   ██  █████  ███████ ██   ██     //
//    ██   ██ ██   ██ ██      ██   ██     //
//    ███████ ███████ ███████ ███████     //
//    ██   ██ ██   ██      ██ ██   ██     //
//    ██   ██ ██   ██ ███████ ██   ██     //
//                                        //
//                                        //
////////////////////////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("Culture by Hash", "PEPE") {}
}