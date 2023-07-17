// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wacchi_NFT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     __      __                     .__    .__     //
//    /  \    /  \_____    ____  ____ |  |__ |__|    //
//    \   \/\/   /\__  \ _/ ___\/ ___\|  |  \|  |    //
//     \        /  / __ \\  \__\  \___|   Y  \  |    //
//      \__/\  /  (____  /\___  >___  >___|  /__|    //
//           \/        \/     \/    \/     \/        //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract WAC is ERC1155Creator {
    constructor() ERC1155Creator("Wacchi_NFT", "WAC") {}
}