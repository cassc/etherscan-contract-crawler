// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Power vs Meaning by Gavin Shapiro
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//             ██████   ██████  ██     ██ ███████ ██████              //
//             ██   ██ ██    ██ ██     ██ ██      ██   ██             //
//             ██████  ██    ██ ██  █  ██ █████   ██████              //
//             ██      ██    ██ ██ ███ ██ ██      ██   ██             //
//             ██       ██████   ███ ███  ███████ ██   ██             //
//                                                                    //
//                            __   _____                              //
//                            \ \ / / __|                             //
//                             \ V /\__ \                             //
//                              \_/ |___/                             //
//                                                                    //
//                                                                    //
//     ███    ███ ███████  █████  ███    ██ ██ ███    ██  ██████      //
//     ████  ████ ██      ██   ██ ████   ██ ██ ████   ██ ██           //
//     ██ ████ ██ █████   ███████ ██ ██  ██ ██ ██ ██  ██ ██   ███     //
//     ██  ██  ██ ██      ██   ██ ██  ██ ██ ██ ██  ██ ██ ██    ██     //
//     ██      ██ ███████ ██   ██ ██   ████ ██ ██   ████  ██████      //
//                                                                    //
//                                                                    //
//                          by Gavin Shapiro                          //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//      "Modernity is a deal:                                         //
//       Humans agree to give up meaning in exchange for power."      //
//                                                                    //
//                                           -Yuval Noah Harari       //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract PVM is ERC721Creator {
    constructor() ERC721Creator("Power vs Meaning by Gavin Shapiro", "PVM") {}
}