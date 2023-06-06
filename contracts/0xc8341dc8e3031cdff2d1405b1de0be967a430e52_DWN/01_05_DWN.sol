// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DAWN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//      _______          ___   _     //
//     |  __ \ \        / / \ | |    //
//     | |  | \ \  /\  / /|  \| |    //
//     | |  | |\ \/  \/ / | . ` |    //
//     | |__| | \  /\  /  | |\  |    //
//     |_____/   \/  \/   |_| \_|    //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract DWN is ERC721Creator {
    constructor() ERC721Creator("DAWN", "DWN") {}
}