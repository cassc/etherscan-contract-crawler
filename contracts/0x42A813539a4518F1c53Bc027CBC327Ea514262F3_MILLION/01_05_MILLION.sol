// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0000MILLION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ██████   ██████   ██████   ██████      //
//    ██  ████ ██  ████ ██  ████ ██  ████     //
//    ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██     //
//    ████  ██ ████  ██ ████  ██ ████  ██     //
//     ██████   ██████   ██████   ██████      //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MILLION is ERC721Creator {
    constructor() ERC721Creator("0000MILLION", "MILLION") {}
}