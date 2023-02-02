// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exploring Freerealism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     .____  _     _ .     .____   ___/           //
//     /      `.   /  /     /     .'  /\ |   |     //
//     |__.     \,'   |     |__.  |  / | `.__|     //
//     |       ,'\    |     |     |,'  |     |     //
//     /----/ /   \   /---/ /     /`---'     |     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract EXFL04 is ERC721Creator {
    constructor() ERC721Creator("Exploring Freerealism", "EXFL04") {}
}