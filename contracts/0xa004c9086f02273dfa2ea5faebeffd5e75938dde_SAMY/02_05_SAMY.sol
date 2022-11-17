// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SAM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//      _________  ______   __________________    //
//     /   _____/ /  __  \  \      \__    ___/    //
//     \_____  \  >      <  /   |   \|    |       //
//     /        \/   --   \/    |    \    |       //
//    /_______  /\______  /\____|__  /____|       //
//            \/        \/         \/             //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract SAMY is ERC721Creator {
    constructor() ERC721Creator("SAM", "SAMY") {}
}