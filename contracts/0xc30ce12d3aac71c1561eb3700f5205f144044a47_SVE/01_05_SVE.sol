// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//       _______  __________________  _  ______    //
//      / __/ _ \/  _/_  __/  _/ __ \/ |/ / __/    //
//     / _// // // /  / / _/ // /_/ /    /\ \      //
//    /___/____/___/ /_/ /___/\____/_/|_/___/      //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract SVE is ERC721Creator {
    constructor() ERC721Creator("EDITIONS", "SVE") {}
}