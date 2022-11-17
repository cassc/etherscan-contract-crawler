// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xINCARN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//        __    _______________    //
//       / /   /  _/ ____/ ___/    //
//      / /    / // __/  \__ \     //
//     / /____/ // /___ ___/ /     //
//    /_____/___/_____//____/      //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract INCARN is ERC721Creator {
    constructor() ERC721Creator("0xINCARN", "INCARN") {}
}