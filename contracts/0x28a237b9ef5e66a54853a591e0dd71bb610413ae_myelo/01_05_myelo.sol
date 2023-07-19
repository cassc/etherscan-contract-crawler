// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Five Senses
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//     /\/|                   touch    _         /\/|    //
//    |/\/ sight                      | |       |/\/     //
//           _ __ ___  _   _  ___| | ___ sound           //
//          | '_ ` _ \| | | |/ _ \ |/ _ \                //
//          | | | | | | |_| |  __/ | (_) |               //
//       smell   |_| |_| |_|\__, |\___|_|\___/           //
//                      __/ |  taste                     //
//                     |___/                             //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract myelo is ERC721Creator {
    constructor() ERC721Creator("The Five Senses", "myelo") {}
}