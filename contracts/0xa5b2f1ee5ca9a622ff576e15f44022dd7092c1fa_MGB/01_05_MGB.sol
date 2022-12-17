// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitterling light
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//    _____ .-.  .-. _____'          ___ |___|____ ____|    //
//    ____<(   )(   )___/_  (/)     (   )|   |  ' |    |    //
//          `-'  `-'                 `|                     //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract MGB is ERC1155Creator {
    constructor() ERC1155Creator("Glitterling light", "MGB") {}
}