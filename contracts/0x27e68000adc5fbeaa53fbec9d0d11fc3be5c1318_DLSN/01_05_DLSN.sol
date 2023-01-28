// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: de/usion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//         888                 d88P                   d8b                       //
//         888                d88P                    Y8P                       //
//         888               d88P                                               //
//     .d88888  .d88b.      d88P    888  888 .d8888b  888  .d88b.  88888b.      //
//    d88" 888 d8P  Y8b    d88P     888  888 88K      888 d88""88b 888 "88b     //
//    888  888 88888888   d88P      888  888 "Y8888b. 888 888  888 888  888     //
//    Y88b 888 Y8b.      d88P       Y88b 888      X88 888 Y88..88P 888  888     //
//     "Y88888  "Y8888  d88P         "Y88888  88888P' 888  "Y88P"  888  888     //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract DLSN is ERC721Creator {
    constructor() ERC721Creator("de/usion", "DLSN") {}
}