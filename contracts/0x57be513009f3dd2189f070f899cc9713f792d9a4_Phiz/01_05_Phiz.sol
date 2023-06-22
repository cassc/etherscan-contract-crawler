// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phizes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//      _____  _     _                 //
//     |  __ \| |   (_)                //
//     | |__) | |__  _ _______ ___     //
//     |  ___/| '_ \| |_  / _ / __|    //
//     | |    | | | | |/ |  __\__ \    //
//     |_|    |_| |_|_/___\___|___/    //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract Phiz is ERC721Creator {
    constructor() ERC721Creator("Phizes", "Phiz") {}
}