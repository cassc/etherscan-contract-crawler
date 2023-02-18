// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Graildom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//      ▄▀  █▄▄▄▄ ██   ▄█ █     ██▄   ████▄ █▀▄▀█     //
//    ▄▀    █  ▄▀ █ █  ██ █     █  █  █   █ █ █ █     //
//    █ ▀▄  █▀▀▌  █▄▄█ ██ █     █   █ █   █ █ ▄ █     //
//    █   █ █  █  █  █ ▐█ ███▄  █  █  ▀████ █   █     //
//     ███    █      █  ▐     ▀ ███▀           █      //
//           ▀      █                         ▀       //
//                 ▀                                  //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Graildom is ERC1155Creator {
    constructor() ERC1155Creator("Graildom", "Graildom") {}
}