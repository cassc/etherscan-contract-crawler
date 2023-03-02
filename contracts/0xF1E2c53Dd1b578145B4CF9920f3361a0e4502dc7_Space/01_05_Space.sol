// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Do Astronauts Dream of Alien Worlds?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    .----. .----. .----.  .--.  .-.   .-. .----.    //
//    | {}  \| {}  }| {_   / {} \ |  `.'  |{ {__      //
//    |     /| .-. \| {__ /  /\  \| |\ /| |.-._} }    //
//    `----' `-' `-'`----'`-'  `-'`-' ` `-'`----'     //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Space is ERC721Creator {
    constructor() ERC721Creator("Do Astronauts Dream of Alien Worlds?", "Space") {}
}