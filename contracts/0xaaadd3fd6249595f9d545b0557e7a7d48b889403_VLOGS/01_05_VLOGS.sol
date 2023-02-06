// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SongADayMann Vlogs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//           _                     //
//          | |                    //
//    __   _| | ___   __ _ ___     //
//    \ \ / / |/ _ \ / _` / __|    //
//     \ V /| | (_) | (_| \__ \    //
//      \_/ |_|\___/ \__, |___/    //
//                    __/ |        //
//                   |___/         //
//                                 //
//                                 //
/////////////////////////////////////


contract VLOGS is ERC1155Creator {
    constructor() ERC1155Creator("SongADayMann Vlogs", "VLOGS") {}
}