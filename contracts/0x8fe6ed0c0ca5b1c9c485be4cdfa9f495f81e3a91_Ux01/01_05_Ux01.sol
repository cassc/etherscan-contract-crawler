// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Acheless life
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//      ___                   _             //
//     / _ \__  ___ __  _ __ | | ___  __    //
//    | | | \ \/ | '_ \| '_ \| |/ \ \/ /    //
//    | |_| |>  <| :_) | | | |   < >  <     //
//     \___//_/\_| .__/|_| |_|_|\_/_/\_\    //
//               |_|                        //
//                                          //
//                                          //
//////////////////////////////////////////////


contract Ux01 is ERC721Creator {
    constructor() ERC721Creator("Acheless life", "Ux01") {}
}