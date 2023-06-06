// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Transcendental
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//    ____   __    _          __   _   ___         __   ___       ____   _           //
//      /    /__)  /_|  /| )  (    / ) (_    /| )  /  ) (_    /| )  /    /_|  /      //
//     (    / (   (  | / |/  __)  (__  /__  / |/  /(_/  /__  / |/  (    (  | (__     //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract TRNS is ERC721Creator {
    constructor() ERC721Creator("Transcendental", "TRNS") {}
}