// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cjsnft editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    ░█▀▀█ ───░█ ░█▀▀▄ ▀▀█▀▀ ░█▄─░█ ░█▀▀▀█     //
//    ░█─── ─▄─░█ ░█─░█ ─░█── ░█░█░█ ─▀▀▀▄▄     //
//    ░█▄▄█ ░█▄▄█ ░█▄▄▀ ─░█── ░█──▀█ ░█▄▄▄█     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract CJDTNS is ERC1155Creator {
    constructor() ERC1155Creator("cjsnft editions", "CJDTNS") {}
}