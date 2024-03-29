// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Boneys Imagined
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//    ▀█▀ █░█ █▀▀   █▄▄ █▀█ █▄░█ █▀▀ █▄█ █▀   █ █▀▄▀█ ▄▀█ █▀▀ █ █▄░█ █▀▀ █▀▄                                                                                          //
//    ░█░ █▀█ ██▄   █▄█ █▄█ █░▀█ ██▄ ░█░ ▄█   █ █░▀░█ █▀█ █▄█ █ █░▀█ ██▄ █▄▀                                                                                          //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//     *///////////////*///////////////*///////////////*///////////////*///////////////                                                                               //
//     *///////////////*///////////////*///////////////*///////////////*///////////////                                                                               //
//     *///////////////*///////////////*///////////////*///////////////*///////////////                                                                               //
//     *///////////////*///////////////*///////////////*///////////////*///////////////                                                                               //
//     *///////////////*///////////////*///////////////*///////////////*///////////////                                                                               //
//     */*/*/*/*/*/*/*/*/*/*/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/*/*/*/*/*/*/*/*/*/*/                                                                               //
//     *///////////////*///%&&***********************************&&////*///////@@//////                                                                               //
//     *///////*///////*/&&*,,                                   ,,&&&/*/////@@@///////                                                                               //
//     *//////////////%%%,,                                        @@@/*///@@//////////                                                                               //
//     *///*///*///*//@@@               *****@@@@@**.  *****@@@@@**&@@/*///@@@@/////*//                                                                               //
//     *//////////////@@@  &@@          //@@@@@@@@//,  //@@@@@@@@//%@@/*/////@@@///////                                                                               //
//     *///////*//////@@@  &@@          ...,,,,.....   ...,,,,......,,&&//////@@@//////                                                                               //
//     *//////////////@@@  ***%%,                                     **&&&////////////                                                                               //
//     ***************@@@     **%%%%%   %%.  %%,  %%   %%.  %%,  &&%%%%%@@@&&&&&*******                                                                               //
//     *//////////////@@@%%%%%%%@@@@@%%%@@%%%@@&%%@@%%%@@%%%@@&%%@@&%%%%%%%%%###&&(////                                                                               //
//     *///////*//////###@@(////@@@@@///@@(//@@#//@@///@@(//@@#//@@@@@@@@@@@@&&&##/////                                                                               //
//     *///////////////*/@@,    ,,,,,   ,,   ,,.  ,,   ,,   ,,.  //,,,@@###(((((///////                                                                               //
//     *///*///*///*///*///&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/////*///*///*///                                                                               //
//     *///////////////*///@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@(((/*///////////////                                                                               //
//     *///////*///////*///@@@                                   @@////*///////*///////                                                                               //
//     *///////////////*///@@@     %%%%%%%%%%%%%/     %%%%%%%%%%%@@////*///////////////                                                                               //
//     */*/*/*/*/*/*/*/*/*/@@@     @@///////////,     ///////////@@*/*/*/*/*/*/*/*/*/*/                                                                               //
//     *///////////////*///@@@     @@@@@@@@@@@@@#     @@@@@@@@@@@@@////*///////////////                                                                               //
//     *///////*///////*///@@@     @@.. .......       . ....... [email protected]@////*///////*///////                                                                               //
//     *///////////////*///@@@     @@&&&&&&&&&&&(     &&&&&&&&&&&@@////*///////////////                                                                               //
//     *///*///*///*///*///@@@     @@***********,     ***********@@*///*///*///*///*///                                                                               //
//     *///////////////*///@@@     @@%%%%%%%%%%%/     %%%%%%%%%%%@@////*///////////////                                                                               //
//     *///////*///////*///@@@     @@***********,     ***********@@////*///////*///////                                                                               //
//     *///////////////*///@@@     @@@@@@@@@@@@@#     @@@@@@@@@@@@@////*///////////////                                                                               //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BONI is ERC721Creator {
    constructor() ERC721Creator("The Boneys Imagined", "BONI") {}
}