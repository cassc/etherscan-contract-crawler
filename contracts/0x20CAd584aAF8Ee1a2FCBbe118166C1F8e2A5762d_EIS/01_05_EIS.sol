// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everything is Simple
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//     ,---.,--.                                           ,--.,--.,--.                      ,--.                             //
//    /  .-'|  | ,---. ,--.   ,--. ,---. ,--.--. ,---.     |  |`--'|  |,-. ,---.      ,---.,-'  '-. ,--,--.,--.--. ,---.      //
//    |  `-,|  || .-. ||  |.'.|  || .-. :|  .--'(  .-'     |  |,--.|     /| .-. :    (  .-''-.  .-'' ,-.  ||  .--'(  .-'      //
//    |  .-'|  |' '-' '|   .'.   |\   --.|  |   .-'  `)    |  ||  ||  \  \\   --.    .-'  `) |  |  \ '-'  ||  |   .-'  `)     //
//    `--'  `--' `---' '--'   '--' `----'`--'   `----'     `--'`--'`--'`--'`----'    `----'  `--'   `--`--'`--'   `----'      //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EIS is ERC1155Creator {
    constructor() ERC1155Creator("Everything is Simple", "EIS") {}
}