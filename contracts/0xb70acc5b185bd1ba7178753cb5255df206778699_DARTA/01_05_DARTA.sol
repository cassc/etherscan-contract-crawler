// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DARTA KATRINA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    8888888b.        d8888 8888888b. 88888888888     d8888     //
//    888  "Y88b      d88888 888   Y88b    888        d88888     //
//    888    888     d88P888 888    888    888       d88P888     //
//    888    888    d88P 888 888   d88P    888      d88P 888     //
//    888    888   d88P  888 8888888P"     888     d88P  888     //
//    888    888  d88P   888 888 T88b      888    d88P   888     //
//    888  .d88P d8888888888 888  T88b     888   d8888888888     //
//    8888888P" d88P     888 888   T88b    888  d88P     888     //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract DARTA is ERC1155Creator {
    constructor() ERC1155Creator("DARTA KATRINA", "DARTA") {}
}