// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ELIZMIL editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     __ _ _               _ _ _        //
//      /__\ (_)_____ __ ___ (_) | |     //
//     /_\ | | |_  / '_ ` _ \| | | |     //
//    //__ | | |/ /| | | | | | | | |     //
//    \__/ |_|_/___|_| |_| |_|_|_|_|     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract MIL is ERC1155Creator {
    constructor() ERC1155Creator("ELIZMIL editions", "MIL") {}
}