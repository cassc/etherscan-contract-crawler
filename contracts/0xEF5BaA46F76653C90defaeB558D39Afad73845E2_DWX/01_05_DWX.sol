// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dylan Wade Experiments
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ██████  ██     ██ ██   ██     //
//    ██   ██ ██     ██  ██ ██      //
//    ██   ██ ██  █  ██   ███       //
//    ██   ██ ██ ███ ██  ██ ██      //
//    ██████   ███ ███  ██   ██     //
//                                  //
//                                  //
//////////////////////////////////////


contract DWX is ERC721Creator {
    constructor() ERC721Creator("Dylan Wade Experiments", "DWX") {}
}