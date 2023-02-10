// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Teenage Mutant Ninja Pepes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     ________  ____   ______      //
//     /_  __/  |/  / | / / __ \    //
//      / / / /|_/ /  |/ / /_/ /    //
//     / / / /  / / /|  / ____/     //
//    /_/ /_/  /_/_/ |_/_/          //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract TMNP is ERC1155Creator {
    constructor() ERC1155Creator("Teenage Mutant Ninja Pepes", "TMNP") {}
}