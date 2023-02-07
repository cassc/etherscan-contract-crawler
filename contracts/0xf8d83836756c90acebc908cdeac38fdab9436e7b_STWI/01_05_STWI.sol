// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stellar Wonders I
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//       _____   _______  __          __    _____     //
//      / ____| |__   __| \ \        / /   |_   _|    //
//     | (___      | |     \ \  /\  / /      | |      //
//      \___ \     | |      \ \/  \/ /       | |      //
//      ____) |    | |       \  /\  /       _| |_     //
//     |_____/     |_|        \/  \/       |_____|    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract STWI is ERC1155Creator {
    constructor() ERC1155Creator("Stellar Wonders I", "STWI") {}
}