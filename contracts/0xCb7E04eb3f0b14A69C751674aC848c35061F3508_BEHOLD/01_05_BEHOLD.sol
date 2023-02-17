// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Beholders by 0xFiendish
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//    Trying to find the true meaning of my existence, with the artistic guidance of web3 peers and AI. Documenting my efforts here.     //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BEHOLD is ERC1155Creator {
    constructor() ERC1155Creator("The Beholders by 0xFiendish", "BEHOLD") {}
}