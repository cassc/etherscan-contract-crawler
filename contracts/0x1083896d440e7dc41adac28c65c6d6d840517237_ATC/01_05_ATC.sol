// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Above the cloudz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     █████  ████████  ██████     //
//    ██   ██    ██    ██          //
//    ███████    ██    ██          //
//    ██   ██    ██    ██          //
//    ██   ██    ██     ██████     //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract ATC is ERC721Creator {
    constructor() ERC721Creator("Above the cloudz", "ATC") {}
}