// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Go_on_magazine
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      ________ ________       ________    _______        //
//     /  _____/ \_____  \      \_____  \   \      \       //
//    /   \  ___  /   |   \      /   |   \  /   |   \      //
//    \    \_\  \/    |    \    /    |    \/    |    \     //
//     \______  /\_______  /    \_______  /\____|__  /     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract goonnft is ERC721Creator {
    constructor() ERC721Creator("Go_on_magazine", "goonnft") {}
}