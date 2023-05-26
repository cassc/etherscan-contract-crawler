// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artsarity
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//       ____  _____  _____  ____   ____  _____  _  _____ __  __    //
//      / () \ | () )|_   _|(_ (_` / () \ | () )| ||_   _|\ \/ /    //
//     /__/\__\|_|\_\  |_| .__)__)/__/\__\|_|\_\|_|  |_|   |__|     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract sari is ERC721Creator {
    constructor() ERC721Creator("Artsarity", "sari") {}
}