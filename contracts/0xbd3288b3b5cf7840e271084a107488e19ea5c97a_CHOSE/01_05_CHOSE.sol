// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chose It
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//        __    ________  ______  __    //
//       / /   /  _/ __ )/ __ ) \/ /    //
//      / /    / // __  / __  |\  /     //
//     / /____/ // /_/ / /_/ / / /      //
//    /_____/___/_____/_____/ /_/       //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract CHOSE is ERC721Creator {
    constructor() ERC721Creator("Chose It", "CHOSE") {}
}