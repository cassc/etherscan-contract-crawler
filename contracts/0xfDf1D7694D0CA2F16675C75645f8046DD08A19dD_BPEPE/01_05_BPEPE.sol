// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bold Pepes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    ██████   ██████  ██      ██████      ██████  ███████ ██████  ███████ ███████     //
//    ██   ██ ██    ██ ██      ██   ██     ██   ██ ██      ██   ██ ██      ██          //
//    ██████  ██    ██ ██      ██   ██     ██████  █████   ██████  █████   ███████     //
//    ██   ██ ██    ██ ██      ██   ██     ██      ██      ██      ██           ██     //
//    ██████   ██████  ███████ ██████      ██      ███████ ██      ███████ ███████     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract BPEPE is ERC721Creator {
    constructor() ERC721Creator("Bold Pepes", "BPEPE") {}
}