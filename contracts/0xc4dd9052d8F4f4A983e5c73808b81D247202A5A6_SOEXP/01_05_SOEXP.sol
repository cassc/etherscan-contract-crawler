// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SOCIAL EXPERIMENT EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//     ▄▀▀ ▄▀▄ ▄▀▀ █ ▄▀▄ █     ██▀ ▀▄▀ █▀▄ ██▀ █▀▄ █ █▄ ▄█ ██▀ █▄ █ ▀█▀    //
//     ▄██ ▀▄▀ ▀▄▄ █ █▀█ █▄▄   █▄▄ █ █ █▀  █▄▄ █▀▄ █ █ ▀ █ █▄▄ █ ▀█  █     //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract SOEXP is ERC1155Creator {
    constructor() ERC1155Creator("SOCIAL EXPERIMENT EDITION", "SOEXP") {}
}