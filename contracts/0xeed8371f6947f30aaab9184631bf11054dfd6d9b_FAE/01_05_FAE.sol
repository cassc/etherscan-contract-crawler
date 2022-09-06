// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE NYC JUNGLE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                         //          //
//    //    ooooooooo.                         oooo   o8o                             oooooooooooo            o8o             .o88o.  .o88o.     //    //
//    //    `888   `Y88.                       `888   `"'                             `888'     `8            `"'             888 `"  888 `"     //    //
//    //     888   .d88'  .oooo.   oooo  oooo   888  oooo  ooo. .oo.    .ooooo.        888          .oooo.   oooo   .ooooo.  o888oo  o888oo      //    //
//    //     888ooo88P'  `P  )88b  `888  `888   888  `888  `888P"Y88b  d88' `88b       888oooo8    `P  )88b  `888  d88' `88b  888     888        //    //
//    //     888          .oP"888   888   888   888   888   888   888  888ooo888       888    "     .oP"888   888  888ooo888  888     888        //    //
//    //     888         d8(  888   888   888   888   888   888   888  888    .o       888         d8(  888   888  888    .o  888     888        //    //
//    //    o888o        `Y888""8o  `V88V"V8P' o888o o888o o888o o888o `Y8bod8P'      o888o        `Y888""8o o888o `Y8bod8P' o888o   o888o       //    //
//    //                                                                                                                                         //    //
//    //                                                                                                                                         //    //
//    //                                                                                                                                         //    //
//    //                               .oMc                                                                                                      //    //
//    //                            .MMMMMP                                                                                                      //    //
//    //                          .MM888MM                                                                                                       //    //
//    //    ....                .MM88888MP                                                                                                       //    //
//    //    MMMMMMMMb.         d8MM8tt8MM                                                                                                        //    //
//    //     MM88888MMMMc `:' dMME8ttt8MM                                                                                                        //    //
//    //      MM88tt888EMMc:dMM8E88tt88MP                                                                                                        //    //
//    //       MM8ttt888EEM8MMEEE8E888MC                                                                                                         //    //
//    //       `MM888t8EEEM8MMEEE8t8888Mb                                                                                                        //    //
//    //        "MM88888tEM8"MME88ttt88MM                                                                                                        //    //
//    //         dM88ttt8EM8"MMM888ttt8MM                                                                                                        //    //
//    //         MM8ttt88MM" " "MMNICKMM"                                                                                                        //    //
//    //         3M88888MM"      "MMMP"                                                                                                          //    //
//    //          "MNICKM"                                                                                                                             //
//                                                                                                                                                     //
//                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FAE is ERC721Creator {
    constructor() ERC721Creator("THE NYC JUNGLE", "FAE") {}
}