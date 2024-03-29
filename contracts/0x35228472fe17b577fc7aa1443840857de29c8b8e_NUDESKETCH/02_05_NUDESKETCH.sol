// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nude Sketch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//       ▄     ▄   ██▄   ▄███▄          ▄▄▄▄▄   █  █▀ ▄███▄     ▄▄▄▄▀ ▄█▄     ▄  █     //
//        █     █  █  █  █▀   ▀        █     ▀▄ █▄█   █▀   ▀ ▀▀▀ █    █▀ ▀▄  █   █     //
//    ██   █ █   █ █   █ ██▄▄        ▄  ▀▀▀▀▄   █▀▄   ██▄▄       █    █   ▀  ██▀▀█     //
//    █ █  █ █   █ █  █  █▄   ▄▀      ▀▄▄▄▄▀    █  █  █▄   ▄▀   █     █▄  ▄▀ █   █     //
//    █  █ █ █▄ ▄█ ███▀  ▀███▀                    █   ▀███▀    ▀      ▀███▀     █      //
//    █   ██  ▀▀▀                                ▀                             ▀       //
//                                                                                     //
//    ███ ▀▄    ▄              ▄  █ ██     ▄▄▄▄▀     ▄█ ▄████                          //
//    █  █  █  █       █   █  █   █ █ █ ▀▀▀ █        ██ █▀   ▀                         //
//    █ ▀ ▄  ▀█       █     █ ██▀▀█ █▄▄█    █        ██ █▀▀                            //
//    █  ▄▀  █        █  █  █ █   █ █  █   █         ▐█ █                              //
//    ███  ▄▀          █ █ █     █     █  ▀           ▐  █                             //
//                      ▀ ▀     ▀     █                   ▀                            //
//                                   ▀                                                 //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract NUDESKETCH is ERC721Creator {
    constructor() ERC721Creator("Nude Sketch", "NUDESKETCH") {}
}