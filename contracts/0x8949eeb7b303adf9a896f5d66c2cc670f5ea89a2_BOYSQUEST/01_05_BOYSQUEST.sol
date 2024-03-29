// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Boy's Quest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@    @@@@@@@@@@    @@@@      @@@@@        @@@@@              @@@@@         @@@@@@@@@@@      @@@@@    //
//    @@@@@   @@@@    @@@@   @@@@    @@@@@         @@@@@@@            @@@@@@@        @@@@@@@@@@@@@@   @@@@@    //
//    @@@@@   @@@@           @@@@  @@@@@          @@@@ @@@@          @@@@ @@@@       @@@@      @@@@   @@@@@    //
//    @@@@@    @@@@@@@@@     @@@@@@@@            @@@@   @@@@        @@@@   @@@@      @@@@@@@@@@@@@    @@@@@    //
//    @@@@@         @@@@@@   @@@@ @@@@@         @@@@     @@@@      @@@@     @@@@     @@@@@@@@@@       @@@@@    //
//    @@@@@           @@@@@  @@@@   @@@@@      @@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@    @@@@     @@@@@    //
//    @@@@@   @@@@@@@@@@@@   @@@@     @@@@@   @@@@         @@@@  @@@@         @@@@   @@@@     @@@@@   @@@@@    //
//    @@@@@      @@@@@@      @@@@       @@@@  @@@           @@@  @@@           @@@   @@@@       @@@@  @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                     A Boy's Quest                                         @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@@                                                                                           @@@@@    //
//    @@@@&                                                                                           @@@@@    //
//    @@@@&                                                                                           @@@@@    //
//    @@@@&                                                                                           @@@@@    //
//    @@@@%                                                                                           @@@@@    //
//    @@@@%                                                                                           @@@@@    //
//    @@@@%                                                                                           @@@@@    //
//    @@@@#                                                                                           @@@@@    //
//    @@@@#                                                                                           @@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOYSQUEST is ERC721Creator {
    constructor() ERC721Creator("A Boy's Quest", "BOYSQUEST") {}
}