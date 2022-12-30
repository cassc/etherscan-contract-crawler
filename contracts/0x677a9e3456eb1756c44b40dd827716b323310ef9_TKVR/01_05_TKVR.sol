// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: William Takeover - Genesis Holder's Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    _______________  __.____   ______________     //
//    \__    ___/    |/ _|\   \ /   /\______   \    //
//      |    |  |      <   \   Y   /  |       _/    //
//      |    |  |    |  \   \     /   |    |   \    //
//      |____|  |____|__ \   \___/    |____|_  /    //
//                      \/                   \/     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract TKVR is ERC721Creator {
    constructor() ERC721Creator("William Takeover - Genesis Holder's Editions", "TKVR") {}
}