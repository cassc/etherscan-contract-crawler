// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nowhere
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                        .                         //
//                        |                         //
//    ;-.   ,-.   , , ,   |-.   ,-.   ;-.   ,-.     //
//    | |   | |   |/|/    | |   |-'   |     |-'     //
//    ' '   `-'   ' '     ' '   `-'   '     `-'     //
//                                                  //
//                  by ravi vora                    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract NWHR is ERC721Creator {
    constructor() ERC721Creator("nowhere", "NWHR") {}
}