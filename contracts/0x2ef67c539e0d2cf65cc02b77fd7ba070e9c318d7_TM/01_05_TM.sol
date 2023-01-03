// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tommy Muench
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    /$$$$$$$$ /$$       /$$    //
//    |__  $$__/| $$$    /$$$    //
//       | $$   | $$$$  /$$$$    //
//       | $$   | $$ $$/$$ $$    //
//       | $$   | $$  $$$| $$    //
//       | $$   | $$\  $ | $$    //
//       | $$   | $$ \/  | $$    //
//       |__/   |__/     |__/    //
//                               //
//                               //
///////////////////////////////////


contract TM is ERC721Creator {
    constructor() ERC721Creator("Tommy Muench", "TM") {}
}