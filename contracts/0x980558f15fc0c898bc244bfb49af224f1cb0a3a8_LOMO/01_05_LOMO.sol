// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lonely Morning #0001
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    #######    //
//    #     #    //
//    #  .  #    //
//    #     #    //
//    #######    //
//               //
//               //
///////////////////


contract LOMO is ERC721Creator {
    constructor() ERC721Creator("Lonely Morning #0001", "LOMO") {}
}