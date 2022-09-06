// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: g/maen
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//              __  __   ___            //
//      .--./) |  |/  `.'   `.          //
//     /.''\\  |   .-.  .-.   '         //
//    | |  | | |  |  |  |  |  | onas    //
//     \`-' /  |  |  |  |  |  |         //
//     /("'`   |  |  |  |  |  |         //
//     \ '---. |  |  |  |  |  |         //
//      /'""'.\|__|  |__|  |__|         //
//     ||     ||                        //
//     \'. __//                         //
//      `'---'                          //
//                                      //
//                                      //
//////////////////////////////////////////


contract gm is ERC721Creator {
    constructor() ERC721Creator("g/maen", "gm") {}
}