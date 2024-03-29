// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Celestial Navigation
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    ,-----.       ,--.               ,--.  ,--.        ,--.                        //
//    '  .--./ ,---. |  | ,---.  ,---.,-'  '-.`--' ,--,--.|  |                       //
//    |  |    | .-. :|  || .-. :(  .-''-.  .-',--.' ,-.  ||  |                       //
//    '  '--'\\   --.|  |\   --..-'  `) |  |  |  |\ '-'  ||  |                       //
//     `-----' `----'`--' `----'`----'  `--'  `--' `--`--'`--'                       //
//    ,--.  ,--.                  ,--.                 ,--.  ,--.                    //
//    |  ,'.|  | ,--,--.,--.  ,--.`--' ,---.  ,--,--.,-'  '-.`--' ,---. ,--,--,      //
//    |  |' '  |' ,-.  | \  `'  / ,--.| .-. |' ,-.  |'-.  .-',--.| .-. ||      \     //
//    |  | `   |\ '-'  |  \    /  |  |' '-' '\ '-'  |  |  |  |  |' '-' '|  ||  |     //
//    `--'  `--' `--`--'   `--'   `--'.`-  /  `--`--'  `--'  `--' `---' `--''--'     //
//                                    `---'                                          //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract CLSTNAV is ERC721Creator {
    constructor() ERC721Creator("Celestial Navigation", "CLSTNAV") {}
}