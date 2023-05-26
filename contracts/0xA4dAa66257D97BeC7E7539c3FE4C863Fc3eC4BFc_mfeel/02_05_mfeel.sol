// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: feelings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//       __           _ _                     //
//      / _| ___  ___| (_)_ __   __ _ ___     //
//     | |_ / _ \/ _ \ | | '_ \ / _` / __|    //
//     |  _|  __/  __/ | | | | | (_| \__ \    //
//     |_|  \___|\___|_|_|_| |_|\__, |___/    //
//                              |___/         //
//                                            //
//                                            //
////////////////////////////////////////////////


contract mfeel is ERC721Creator {
    constructor() ERC721Creator("feelings", "mfeel") {}
}