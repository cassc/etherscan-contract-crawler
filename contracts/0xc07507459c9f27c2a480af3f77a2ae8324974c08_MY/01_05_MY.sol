// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mystery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//        __  ___           __                     //
//       /  |/  /_  _______/ /____  _______  __    //
//      / /|_/ / / / / ___/ __/ _ \/ ___/ / / /    //
//     / /  / / /_/ (__  ) /_/  __/ /  / /_/ /     //
//    /_/  /_/\__, /____/\__/\___/_/   \__, /      //
//           /____/                   /____/       //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MY is ERC721Creator {
    constructor() ERC721Creator("Mystery", "MY") {}
}