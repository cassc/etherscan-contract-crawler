// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nowhere - year one
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                            .                             //
//                            |                             //
//        ;-.   ,-.   , , ,   |-.   ,-.   ;-.   ,-.         //
//        | |   | |   |/|/    | |   |-'   |     |-'         //
//        ' '   `-'   ' '     ' '   `-'   '     `-'         //
//                                                          //
//                      - year one -                        //
//                                                          //
//                      by ravi vora                        //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract NWHR1 is ERC721Creator {
    constructor() ERC721Creator("nowhere - year one", "NWHR1") {}
}