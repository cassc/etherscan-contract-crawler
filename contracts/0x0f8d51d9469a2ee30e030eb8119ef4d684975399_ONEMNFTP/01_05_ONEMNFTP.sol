// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0x1000000NFT PHOTOS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//      ___       _             __  ___  _____  ___     //
//     / _ \__  _/ | /\/\    /\ \ \/ __\/__   \/ _ \    //
//    | | | \ \/ / |/    \  /  \/ / _\    / /\/ /_)/    //
//    | |_| |>  <| / /\/\ \/ /\  / /     / / / ___/     //
//     \___//_/\_\_\/    \/\_\ \/\/      \/  \/         //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract ONEMNFTP is ERC721Creator {
    constructor() ERC721Creator("0x1000000NFT PHOTOS", "ONEMNFTP") {}
}