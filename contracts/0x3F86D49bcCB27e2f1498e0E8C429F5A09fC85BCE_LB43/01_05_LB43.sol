// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Official Installments: BRAAVI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     ,---.   ,---.    .--.    .--..-.   .-.,-.     //
//     | .-.\  | .-.\  / /\ \  / /\ \\ \ / / |(|     //
//     | |-' \ | `-'/ / /__\ \/ /__\ \\ V /  (_)     //
//     | |--. \|   (  |  __  ||  __  | ) /   | |     //
//     | |`-' /| |\ \ | |  |)|| |  |)|(_)    | |     //
//     /( `--' |_| \)\|_|  (_)|_|  (_)       `-'     //
//    (__)         (__)                              //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract LB43 is ERC721Creator {
    constructor() ERC721Creator("Official Installments: BRAAVI", "LB43") {}
}