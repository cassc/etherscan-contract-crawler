// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Night Walk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     _______ _   ___          __    //
//    |__   __| \ | \ \        / /    //
//       | |  |  \| |\ \  /\  / /     //
//       | |  | . ` | \ \/  \/ /      //
//       | |  | |\  |  \  /\  /       //
//       |_|  |_| \_|   \/  \/        //
//                                    //
//                                    //
////////////////////////////////////////


contract TNW is ERC721Creator {
    constructor() ERC721Creator("The Night Walk", "TNW") {}
}