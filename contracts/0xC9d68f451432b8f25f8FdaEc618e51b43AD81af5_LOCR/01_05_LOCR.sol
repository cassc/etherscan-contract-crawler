// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LoliCraft
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//      _        _    _ _            //
//     | |   ___| |  (_) |   ___     //
//     | |__/ _ \ |__| | |__/ _ \    //
//     |____\___/____|_|____\___/    //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract LOCR is ERC1155Creator {
    constructor() ERC1155Creator("LoliCraft", "LOCR") {}
}