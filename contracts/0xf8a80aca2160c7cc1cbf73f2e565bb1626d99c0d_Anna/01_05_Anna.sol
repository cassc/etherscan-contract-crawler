// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anna
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//       _____    _______    _______      _____       //
//      /  _  \   \      \   \      \    /  _  \      //
//     /  /_\  \  /   |   \  /   |   \  /  /_\  \     //
//    /    |    \/    |    \/    |    \/    |    \    //
//    \____|__  /\____|__  /\____|__  /\____|__  /    //
//            \/         \/         \/         \/     //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Anna is ERC721Creator {
    constructor() ERC721Creator("Anna", "Anna") {}
}