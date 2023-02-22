// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moon Drops
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//              _.._        //
//            .' .-'`       //
//           /  /  MOON     //
//           |  |  DROPS    //
//           \  '.___.;     //
//            '._  _.'      //
//               ``         //
//                          //
//                          //
//////////////////////////////


contract MOON is ERC721Creator {
    constructor() ERC721Creator("Moon Drops", "MOON") {}
}