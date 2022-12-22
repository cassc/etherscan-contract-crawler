// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Hounds Tribute by Hagakure.eth
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//     ____  ____       ____  _____  _     ____  _  ____  ____     //
//    /  _ \/ ___\     / ___\/__ __\/ \ /\/  _ \/ \/  _ \/ ___\    //
//    | | \||    \     |    \  / \  | | ||| | \|| || / \||    \    //
//    | |_/|\___ |     \___ |  | |  | \_/|| |_/|| || \_/|\___ |    //
//    \____/\____/_____\____/  \_/  \____/\____/\_/\____/\____/    //
//                \____\                                           //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract MHT is ERC1155Creator {
    constructor() ERC1155Creator("Mutant Hounds Tribute by Hagakure.eth", "MHT") {}
}