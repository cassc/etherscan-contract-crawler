// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Contract No1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//    .___  ______   ________________________      __     //
//    |   |/  __  \  \_   _____/\__    ___/  \    /  \    //
//    |   |>      <   |    __)    |    |  \   \/\/   /    //
//    |   /   --   \  |     \     |    |   \        /     //
//    |___\______  /  \___  /     |____|    \__/\  /      //
//               \/       \/                     \/       //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract I8NFT is ERC721Creator {
    constructor() ERC721Creator("Contract No1", "I8NFT") {}
}