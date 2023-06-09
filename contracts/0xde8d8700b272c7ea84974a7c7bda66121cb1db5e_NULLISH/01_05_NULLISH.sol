// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nullish Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    ▒█▄░▒█ ▒█░▒█ ▒█░░░ ▒█░░░ ▀█▀ ▒█▀▀▀█ ▒█░▒█     //
//    ▒█▒█▒█ ▒█░▒█ ▒█░░░ ▒█░░░ ▒█░ ░▀▀▀▄▄ ▒█▀▀█     //
//    ▒█░░▀█ ░▀▄▄▀ ▒█▄▄█ ▒█▄▄█ ▄█▄ ▒█▄▄▄█ ▒█░▒█     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract NULLISH is ERC1155Creator {
    constructor() ERC1155Creator("Nullish Editions", "NULLISH") {}
}