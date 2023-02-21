// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Old Man
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     _   .-')      ('-.         .-') _      //
//    ( '.( OO )_   ( OO ).-.    ( OO ) )     //
//     ,--.   ,--.) / . --. /,--./ ,--,'      //
//     |   `.'   |  | \-.  \ |   \ |  |\      //
//     |         |.-'-'  |  ||    \|  | )     //
//     |  |'.'|  | \| |_.'  ||  .     |/      //
//     |  |   |  |  |  .-.  ||  |\    |       //
//     |  |   |  |  |  | |  ||  | \   |       //
//     `--'   `--'  `--' `--'`--'  `--'       //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MAN is ERC721Creator {
    constructor() ERC721Creator("The Old Man", "MAN") {}
}