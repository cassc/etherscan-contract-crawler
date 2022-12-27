// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Galaxy Globes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//              ____         //
//           .-" +' "-.      //
//          /.'.'GG'*`.\     //
//         |:.*'/\-\. ':|    //
//         |:.'.||"|.'*:|    //
//          \:~^~^~^~^:/     //
//           /`-....-'\      //
//          /          \     //
//          `-.,____,.-'     //
//                           //
//                           //
///////////////////////////////


contract GG is ERC721Creator {
    constructor() ERC721Creator("Galaxy Globes", "GG") {}
}