// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marc Aight's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//                                                                                             //
//     _______  _______  _______  _______    _______ _________ _______          _________      //
//    (       )(  ___  )(  ____ )(  ____ \  (  ___  )\__   __/(  ____ \|\     /|\__   __/      //
//    | () () || (   ) || (    )|| (    \/  | (   ) |   ) (   | (    \/| )   ( |   ) (         //
//    | || || || (___) || (____)|| |        | (___) |   | |   | |      | (___) |   | |         //
//    | |(_)| ||  ___  ||     __)| |        |  ___  |   | |   | | ____ |  ___  |   | |         //
//    | |   | || (   ) || (\ (   | |        | (   ) |   | |   | | \_  )| (   ) |   | |         //
//    | )   ( || )   ( || ) \ \__| (____/\  | )   ( |___) (___| (___) || )   ( |   | |         //
//    |/     \||/     \||/   \__/(_______/  |/     \|\_______/(_______)|/     \|   )_(         //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract MA is ERC1155Creator {
    constructor() ERC1155Creator("Marc Aight's Editions", "MA") {}
}