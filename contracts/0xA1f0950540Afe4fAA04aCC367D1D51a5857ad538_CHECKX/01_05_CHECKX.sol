// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checkx
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//     ██████ ██   ██ ███████  ██████ ██   ██ ██   ██     //
//    ██      ██   ██ ██      ██      ██  ██   ██ ██      //
//    ██      ███████ █████   ██      █████     ███       //
//    ██      ██   ██ ██      ██      ██  ██   ██ ██      //
//     ██████ ██   ██ ███████  ██████ ██   ██ ██   ██     //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract CHECKX is ERC721Creator {
    constructor() ERC721Creator("Checkx", "CHECKX") {}
}