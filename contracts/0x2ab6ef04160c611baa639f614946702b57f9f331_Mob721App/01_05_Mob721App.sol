// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mob721App
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    get poor    //
//                //
//                //
////////////////////


contract Mob721App is ERC721Creator {
    constructor() ERC721Creator("Mob721App", "Mob721App") {}
}