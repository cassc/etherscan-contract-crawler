// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hugo Faz - CryptoArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                ▌▄                                               //
//                                 ████▓                                           //
//                                  ███████µ                                       //
//                                    ╙██████                                      //
//                          ,       ,   ██████                                     //
//                         ▀█       ─██▄ ╙█████▄                                   //
//                      ▌  ▄          ╙███▓ ████▌                                  //
//                     ▄█▌ █▄,           ████████─                                 //
//                 █████████████▌▄       ▐███▌████                                 //
//                  ██──███████████▄      ████ ████                                //
//                  █▓   ██████ ██▌██      █████████µ                              //
//                 ──     ─██  █▓▀─▄▀█▄    ██████████▄                             //
//                     ▄           ███      ██████████                             //
//                     ┴             ▓███   ▀██████████                            //
//                          ▄█─       ████▌  ███████████                           //
//                         ███        ╙█████─ ▀█████████▌                          //
//                          ▀          ╙███████▄█████████                          //
//                                      █████████████████─                         //
//         Γ▀▀███▀▀   ▀▀███▀▀Γ           █████████████████       ▀▀▓██▀▀▀▀▀▀███    //
//            ███       ╫██            ▄█▀▀╙   ███████████▌        ╫██       ─█    //
//            ███       ╫██           ▀██▀ j██╨ ▐█▀████████        ╫██     ▌       //
//            ███       ╫██                 ▀██████████████        ╫██   ▄██       //
//            ███───────▓██            ─█    █▀▌███─└██████        ╫██───╝██       //
//            ███       ╫██                  ──████  ██████        ╫██     ▌       //
//            ███       ╫██                    ▐███▌╓██████        ╫██             //
//            ███       ╫██              ▄     ███▀████████        ╫██             //
//          ───────   ───────                 ─████████████      ───────           //
//                                ██████           ╓████████▄                      //
//                            ███████████    ,, ▄▌██████▀╫█████▌                   //
//                           ███████████▄    ╝╝▀╙╙╨██▌   ╙██─ └███▌                //
//                         ▄██████████████       ¬▀             ▓████              //
//                        ─███████████████  X─███▌                ▀███▄            //
//                        ▐██████████████▌    ██╫B                   ▀             //
//                             ▀████▌╨        █▌                                   //
//                                             ¬                                   //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract HFCRP is ERC721Creator {
    constructor() ERC721Creator("Hugo Faz - CryptoArt", "HFCRP") {}
}