// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Setsunai
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//       __   _______  _____  __    //
//      / /  /  _/ _ )/ _ ) \/ /    //
//     / /___/ // _  / _  |\  /     //
//    /____/___/____/____/ /_/      //
//                                  //
//                                  //
//////////////////////////////////////


contract STSN is ERC721Creator {
    constructor() ERC721Creator("Setsunai", "STSN") {}
}