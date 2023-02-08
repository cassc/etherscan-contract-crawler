// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Check Norris Pepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//       _____ _    _ ______ _____ _  __    //
//      / ____| |  | |  ____/ ____| |/ /    //
//     | |    | |__| | |__ | |    | ' /     //
//     | |    |  __  |  __|| |    |  <      //
//     | |____| |  | | |___| |____| . \     //
//      \_____|_|  |_|______\_____|_|\_\    //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CNP is ERC1155Creator {
    constructor() ERC1155Creator("Check Norris Pepe", "CNP") {}
}