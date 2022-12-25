// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XERIESJAME DROP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ░█░█░█▀▀░█▀▄░▀█▀░█▀▀░█▀▀░▀▀█░█▀█░█▄█░█▀▀    //
//    ░▄▀▄░█▀▀░█▀▄░░█░░█▀▀░▀▀█░░░█░█▀█░█░█░█▀▀    //
//    ░█░█░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░███░▀░▀░█░█░▀▀▀    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract XERIESJAME is ERC1155Creator {
    constructor() ERC1155Creator("XERIESJAME DROP", "XERIESJAME") {}
}