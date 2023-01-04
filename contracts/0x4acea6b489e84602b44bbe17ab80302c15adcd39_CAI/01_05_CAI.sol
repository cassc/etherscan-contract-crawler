// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Charlesai
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    ╔═╗╦  ╔═╗╦═╗╔╦╗  ╦╔═╗  ╔═╗╦═╗╔╦╗      //
//    ╠═╣║  ╠═╣╠╦╝ ║   ║╚═╗  ╠═╣╠╦╝ ║       //
//    ╩ ╩╩  ╩ ╩╩╚═ ╩   ╩╚═╝  ╩ ╩╩╚═ ╩       //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CAI is ERC1155Creator {
    constructor() ERC1155Creator("Charlesai", "CAI") {}
}