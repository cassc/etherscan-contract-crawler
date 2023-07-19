// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bom dia Victor :)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    Contrato feito para registrar na blockchain um Bom dia especialmente para você!    //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract GMVC is ERC721Creator {
    constructor() ERC721Creator("Bom dia Victor :)", "GMVC") {}
}