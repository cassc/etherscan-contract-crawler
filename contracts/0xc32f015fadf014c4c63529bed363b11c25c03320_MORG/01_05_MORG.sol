// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mouth of the Rio Grande
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//       _____   ________ __________  ________     //
//      /     \  \_____  \\______   \/  _____/     //
//     /  \ /  \  /   |   \|       _/   \  ___     //
//    /    Y    \/    |    \    |   \    \_\  \    //
//    \____|__  /\_______  /____|_  /\______  /    //
//            \/         \/       \/        \/     //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MORG is ERC721Creator {
    constructor() ERC721Creator("Mouth of the Rio Grande", "MORG") {}
}