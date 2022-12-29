// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Liquid
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//          _              \           .                          _    //
//       ___/   ___  .___  |   ,       |   `   ___.  ,   . `   ___/    //
//      /   |  /   ` /   \ |  /        |   | .'   `  |   | |  /   |    //
//     ,'   | |    | |   ' |-<         |   | |    |  |   | | ,'   |    //
//     `___,' `.__/| /     /  \_      /\__ /  `---|. `._/| / `___,'    //
//          `                                     |/              `    //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract DL is ERC721Creator {
    constructor() ERC721Creator("Dark Liquid", "DL") {}
}