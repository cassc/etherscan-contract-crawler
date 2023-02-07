// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Progression by Hash
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    ██   ██  █████  ███████ ██   ██     //
//    ██   ██ ██   ██ ██      ██   ██     //
//    ███████ ███████ ███████ ███████     //
//    ██   ██ ██   ██      ██ ██   ██     //
//    ██   ██ ██   ██ ███████ ██   ██     //
//                                        //
//                                        //
////////////////////////////////////////////


contract PRG is ERC1155Creator {
    constructor() ERC1155Creator("Progression by Hash", "PRG") {}
}