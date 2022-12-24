// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artsarity - Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//       ____  _____  _____  ____   ____  _____  _  _____ __  __    //
//      / () \ | () )|_   _|(_ (_` / () \ | () )| ||_   _|\ \/ /    //
//     /__/\__\|_|\_\  |_| .__)__)/__/\__\|_|\_\|_|  |_|   |__|     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract sarit is ERC1155Creator {
    constructor() ERC1155Creator("Artsarity - Editions", "sarit") {}
}