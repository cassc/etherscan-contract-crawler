// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: T3 - Masterpieces
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    ___________________     _____       //
//    \__    ___/\_____  \   /     \      //
//      |    |     _(__  <  /  \ /  \     //
//      |    |    /       \/    Y    \    //
//      |____|   /______  /\____|__  /    //
//                      \/         \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract T3M is ERC721Creator {
    constructor() ERC721Creator("T3 - Masterpieces", "T3M") {}
}