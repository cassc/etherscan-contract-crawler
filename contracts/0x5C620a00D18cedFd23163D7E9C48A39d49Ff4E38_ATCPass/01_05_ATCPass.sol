// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ATCPass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    Ｉ Ｌ Ｅ Ｉ Ｖ    //
//    Ｌ Ｅ Ｉ Ｖ Ｉ    //
//    Ｅ Ｉ Ｖ Ｉ Ｌ    //
//    Ｉ Ｖ Ｉ Ｌ Ｅ    //
//    Ｖ Ｉ Ｌ Ｅ Ｉ    //
//                 //
//                 //
/////////////////////


contract ATCPass is ERC1155Creator {
    constructor() ERC1155Creator("ATCPass", "ATCPass") {}
}