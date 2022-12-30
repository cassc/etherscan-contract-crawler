// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: As Above So Below
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//     _______                   __                ________     //
//     \      \   ____   _______/  |_  ___________/   __   \    //
//     /   |   \_/ __ \ /  ___/\   __\/  _ \_  __ \____    /    //
//    /    |    \  ___/ \___ \  |  | (  <_> )  | \/  /    /     //
//    \____|__  /\___  >____  > |__|  \____/|__|    /____/      //
//            \/     \/     \/                                  //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract Nestor9 is ERC721Creator {
    constructor() ERC721Creator("As Above So Below", "Nestor9") {}
}