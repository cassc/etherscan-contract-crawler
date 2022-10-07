// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RetroGraff001
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     ____   ___  ____    __    ____  ____     //
//    (  _ \ / __)(  _ \  /__\  ( ___)( ___)    //
//     )   /( (_-. )   / /(__)\  )__)  )__)     //
//    (_)\_) \___/(_)\_)(__)(__)(__)  (__)      //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract RGRAFF is ERC721Creator {
    constructor() ERC721Creator("RetroGraff001", "RGRAFF") {}
}