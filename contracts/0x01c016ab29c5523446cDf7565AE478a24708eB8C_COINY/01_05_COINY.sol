// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COINYLABS ART 2023 - OPEN EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    COINYLABS ART 2023    //
//    OPEN EDITIONS         //
//                          //
//                          //
//////////////////////////////


contract COINY is ERC1155Creator {
    constructor() ERC1155Creator("COINYLABS ART 2023 - OPEN EDITIONS", "COINY") {}
}