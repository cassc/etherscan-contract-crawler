// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//     /\/|                       _         /\/|    //
//    |/\/                       | |       |/\/     //
//           _ __ ___  _   _  ___| | ___            //
//          | '_ ` _ \| | | |/ _ \ |/ _ \           //
//          | | | | | | |_| |  __/ | (_) |          //
//          |_| |_| |_|\__, |\___|_|\___/           //
//                      __/ |                       //
//                     |___/                        //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract myelo is ERC1155Creator {
    constructor() ERC1155Creator("Editions", "myelo") {}
}