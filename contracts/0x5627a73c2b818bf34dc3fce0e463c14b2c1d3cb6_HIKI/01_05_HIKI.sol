// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HIKI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     //
//    @@@                                                               @@@     //
//    @@@       IIIII    IIIII  IIIIIII  IIIII    IIIII   IIIIIII       @@@     //
//    @@@       IIIII    IIIII  IIIIIII  IIIII   IIIII    IIIIIII       @@@     //
//    @@@       IIIII    IIIII   IIIII   IIIII  IIIII      IIIII        @@@     //
//    @@@       IIIIIIIIIIIIII   IIIII   IIIII IIIII       IIIII        @@@     //
//    @@@       IIIIIIIIIIIIII   IIIII   IIIIIIIIII        IIIII        @@@     //
//    @@@       IIIIIIIIIIIIII   IIIII   IIIIIIIIII        IIIII        @@@     //
//    @@@       IIIII    IIIII   IIIII   IIIII IIIII       IIIII        @@@     //
//    @@@       IIIII    IIIII   IIIII   IIIII  IIIII      IIIII        @@@     //
//    @@@       IIIII    IIIII  IIIIIII  IIIII   IIIII    IIIIIII       @@@     //
//    @@@       IIIII    IIIII  IIIIIII  IIIII    IIIII   IIIIIII       @@@     //
//    @@@                                                               @@@     //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract HIKI is ERC721Creator {
    constructor() ERC721Creator("HIKI", "HIKI") {}
}