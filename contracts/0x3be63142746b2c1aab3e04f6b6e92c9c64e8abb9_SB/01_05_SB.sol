// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sui Bunbun
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    ░▄▀▀░█▒█░█    //
//    ▒▄██░▀▄█░█    //
//                  //
//                  //
//                  //
//////////////////////


contract SB is ERC1155Creator {
    constructor() ERC1155Creator("Sui Bunbun", "SB") {}
}