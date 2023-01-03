// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: scorn
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//       ▄▄▄▄▄   ▄█▄    ████▄ █▄▄▄▄   ▄       //
//      █     ▀▄ █▀ ▀▄  █   █ █  ▄▀    █      //
//    ▄  ▀▀▀▀▄   █   ▀  █   █ █▀▀▌ ██   █     //
//     ▀▄▄▄▄▀    █▄  ▄▀ ▀████ █  █ █ █  █     //
//               ▀███▀          █  █  █ █     //
//                             ▀   █   ██     //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract scorn is ERC721Creator {
    constructor() ERC721Creator("scorn", "scorn") {}
}