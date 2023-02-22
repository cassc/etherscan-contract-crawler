// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Fly
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     ___ ___  ___ ___   ___  _  __ _____     //
//    | o \ __|| o \ __| | __|| | \ V /_ /     //
//    |  _/ _| |  _/ _|  | _| | |_ \ / /(_     //
//    |_| |___||_| |___| |_|  |___||_|/___|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract PPFLYZ is ERC721Creator {
    constructor() ERC721Creator("Pepe Fly", "PPFLYZ") {}
}