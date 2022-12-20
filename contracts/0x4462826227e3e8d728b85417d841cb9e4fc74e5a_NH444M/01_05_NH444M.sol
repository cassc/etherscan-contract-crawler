// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 444 Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     ___   ___  ___   ___  ___   ___         //
//    |\  \ |\  \|\  \ |\  \|\  \ |\  \        //
//    \ \  \\_\  \ \  \\_\  \ \  \\_\  \       //
//     \ \______  \ \______  \ \______  \      //
//      \|_____|\  \|_____|\  \|_____|\  \     //
//             \ \__\     \ \__\     \ \__\    //
//              \|__|      \|__|      \|__|    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract NH444M is ERC1155Creator {
    constructor() ERC1155Creator("444 Editions", "NH444M") {}
}