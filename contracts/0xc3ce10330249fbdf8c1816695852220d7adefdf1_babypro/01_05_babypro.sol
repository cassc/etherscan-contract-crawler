// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: babypro
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//        __          __                             //
//       / /_  ____ _/ /_  __  ______  _________     //
//      / __ \/ __ `/ __ \/ / / / __ \/ ___/ __ \    //
//     / /_/ / /_/ / /_/ / /_/ / /_/ / /  / /_/ /    //
//    /_.___/\__,_/_.___/\__, / .___/_/   \____/     //
//                      /____/_/                     //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract babypro is ERC721Creator {
    constructor() ERC721Creator("babypro", "babypro") {}
}