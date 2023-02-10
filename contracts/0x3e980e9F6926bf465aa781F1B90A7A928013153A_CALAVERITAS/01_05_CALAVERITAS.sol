// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Calaveritas Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//           @@@@@@@@@@@@@@@@@@              //
//         @@@@@@@@@@@@@@@@@@@@@@@           //
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@         //
//      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@        //
//     @@@@@@@@@@@@@@@/      \@@@/   @       //
//    @@@@@@@@@@@@@@@@\      @@  @[email protected]       //
//    @@@@@@@@@@@@@ @@@@@@@@@@  | \@@@@@     //
//    @@@@@@@@@@@@@ @@@@@@@@@\[email protected]_/@@@@@     //
//     @@@@@@@@@@@@@@@/,/,/./'/_|.\'\,\      //
//       @@@@@@@@@@@@@|  | | | | | | | |     //
//                     \_|_|_|_|_|_|_|_|     //
//                                           //
//    @@@@@@@@@@@@@@@@@[email protected]@@    //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract CALAVERITAS is ERC1155Creator {
    constructor() ERC1155Creator("Checks - Calaveritas Edition", "CALAVERITAS") {}
}