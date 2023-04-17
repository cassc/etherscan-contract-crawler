// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REXBITS RUN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//    ██████  ███████ ██   ██ ██████  ██ ████████ ███████     //
//    ██   ██ ██       ██ ██  ██   ██ ██    ██    ██          //
//    ██████  █████     ███   ██████  ██    ██    ███████     //
//    ██   ██ ██       ██ ██  ██   ██ ██    ██         ██     //
//    ██   ██ ███████ ██   ██ ██████  ██    ██    ███████     //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract REXRUN is ERC1155Creator {
    constructor() ERC1155Creator("REXBITS RUN", "REXRUN") {}
}