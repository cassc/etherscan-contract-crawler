// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTravel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    ╭━╮╱╭┳━━━┳━━━━╮╱╱╱╱╱╱╱╱╱╭╮     //
//    ┃┃╰╮┃┃╭━━┫╭╮╭╮┃╱╱╱╱╱╱╱╱╱┃┃     //
//    ┃╭╮╰╯┃╰━━╋╯┃┃┣┻┳━━┳╮╭┳━━┫┃     //
//    ┃┃╰╮┃┃╭━━╯╱┃┃┃╭┫╭╮┃╰╯┃┃━┫┃     //
//    ┃┃╱┃┃┃┃╱╱╱╱┃┃┃┃┃╭╮┣╮╭┫┃━┫╰╮    //
//    ╰╯╱╰━┻╯╱╱╱╱╰╯╰╯╰╯╰╯╰╯╰━━┻━╯    //
//                                   //
//                                   //
///////////////////////////////////////


contract NFTravel is ERC721Creator {
    constructor() ERC721Creator("NFTravel", "NFTravel") {}
}