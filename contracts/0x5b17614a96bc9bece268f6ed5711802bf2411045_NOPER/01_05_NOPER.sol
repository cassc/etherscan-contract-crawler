// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Noper Arts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                 //
//                                                                                                                 //
//         ▌          █           █          █          ▐           ▓          ▐           ▌          ▐            //
//    ▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄▌▄▄▄▄▄▄▄    //
//              ▐           ▌           ▌          ▌          ▐           █          ▌           ▌          ▓      //
//    ▌▄▄▄▄▄▄▄▄▄██████▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄▌▄▄▄▄▄▄▄▄▄▄█▄▄    //
//         █   ▐████████▄     █████          ▐▄▄▄▄▄▄▄   ▐           █          ▐           ▌  ▄▄▄▄▄   ▐            //
//    ▄▄▄▄▄█▄▄▄███████████▄▄▄▄██▄▄█▄▄▄▄▄▄▄▄▄▄███████████████▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄█▌▄▄▄███▄▄▄▄█████████▄▄████▄▄▄▄▄    //
//            ████████████▄ ▌           ▌▄   █████▀▀███████████▄▄       ▄██▄▄        ▌ ▄██████████████████▌ ▓      //
//    ▄▄▄▄▄▄▄████████████████████▄▄▄████████▄████▌ ▄█▄  ▀▀██████████▄▄▄████████▄▄▄▄█▄██████████████████████▄█▄▄    //
//      ▄▄ ▌  ▀██████████████████████████████████▌▐█████▄▄   ▀▀██████████████████████████▀▀██████████▀ █████       //
//    ▄▐███▀   ▄████████████▀▀ ▀██████  ▀▀███████ ▐███▀█████▄     ▀▀████▀    ▀█████████▀     ▀███▀▀▄    █████▄     //
//       ▀▀    ▄█████████▀  ▄█▄  ▀█▀   ██▄ ▀████▀ ▐███   ▀██████▄         ▄█▄▄   ▀██▀   ▄      ▄▄████   ▐████▌     //
//    ▀▀▀▀▀█▀▀█████▀      ▄████       █████       ▐███       ▀██████▄     ██████▄      ███  ▄█████▀     ▄█████▀    //
//         ▌  ████▌  ██▄ ██████     ▄███████▄     ▐███           ▀██████▄▄████████▄    ████████▀    ▄████████▌     //
//    ▌▀▀▀▀▀▀█████  ▓██████████    ▄███  ▀████▄   ▐███         ▄▄████████████▌ ▄█████  █████▀    ▄████████▀██▀▀    //
//          ▄████▌  ▓█████▌ ███▌  ▐███     ▀████▄  ███   ▄▄████████▀▀▀ ▄▄▄███████████  ████    ▄███████  ▀  ▐      //
//    ▀▀▀▀▀██████▌  ▓█████  ▐███  ███▌  ▄▄██████▀  ██████████▀▀  ▄▄███████████▀    ▄██████▌   ███████████▀▀▀▀▀▀    //
//         █▓████   ▓████    ███▌ █████████▀▀  ▄███████▀▀      ██████▀▀   ▓███  ▄█████▀███   ▐███████████▌         //
//    ▀▀▀▀▀▀█████   ████▌    ▐███ █████▀  ▄▄██████▀███▌         ▀         ▐████████▀   ███   ██████████████▀█▀▀    //
//    ▌     █████   ████      ████    ▄██████▀▀    ███▌ ▄████████████████▌▐█████▀      ███   ████████████████      //
//    ▀▀▀▀▀█████▌   ███▌       ███▌  ████▀    ▄▄   ███▌▓██████████████████ ███▀  ▄█▄▄  ███  ████████████████▀▀▀    //
//         █████▌   ▀█▀    ▄   ▐███      ▄▄██████  ███▌▐████████▌▀ ███████▌  ▄████████▄    ▄███████████████        //
//    ▀ ▀▀██████▌        █████▄     ▄▄███████████  ▓███ █████████▀▀▀▀▀▀█████████████████████████▀▀███▀▀▀▀▀▀▀█▀     //
//      ████████████████████████▄████████████████  ▐███ ████████████   ▀██████▀▀▀█▀▀████████▀▀▀  ▌▐█▀       ▐      //
//    ▀████████████████████▀█████████████████████  ▐███ █████████████▀  ▀▀██▌  ▐▀ ▀▀ ▀▀▀▀▀▀█        ▀▀▐▌███▀▀▀     //
//     ▐███████████████▀     ███▀▀█ ▄████████████   ███  ████████████     ██   ▐███        █          ▐▌█▌▀        //
//    ▀  █████████████      █▀▀   ▐██████████████   ███▌ ██████▀          █      ▀▀  █          ▐▌      ▀▀  █      //
//         ▀▀████████▌ ███▌ █     ▐██████████████   ▀██  ▐█████           █          ▌          ▐▌          ▐      //
//         ▌ ██████▀  █           █████▀    ▀████▄▄▄▄▄▄▄▄▄█████     ▓          ▐           ▌          ▐▌           //
//         ▌▐██       █           ████      ▐██████████████████▌    ▓          ▐           ▌          ▐▌           //
//    ▌         █           █      ██▌  ▌    ▀▀██████▀▀▀▀███▀▀█           █          ▌          ▐▌          ▓      //
//    ▄         █           █           ▌         ▄▌     ▓██  ▓▄          █          ▌          ▐▌          █      //
//         █          █           █          █          ▐▌          █          ▐▌          ▌          ▐▌           //
//         █          █          ▄█          █          ▐▄         ▄█▄         ▐▌         ▄▌         ▄▐▌           //
//                                                                                                                 //
//                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOPER is ERC721Creator {
    constructor() ERC721Creator("Noper Arts", "NOPER") {}
}