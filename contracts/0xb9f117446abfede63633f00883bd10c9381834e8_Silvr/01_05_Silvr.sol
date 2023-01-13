// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gems by Silver
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//      ____  _ _                    //
//     / ___|(_) |_   _____ _ __     //
//     \___ \| | \ \ / / _ \ '__|    //
//      ___) | | |\ V /  __/ |       //
//     |____/|_|_| \_/ \___|_|       //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract Silvr is ERC1155Creator {
    constructor() ERC1155Creator("Gems by Silver", "Silvr") {}
}