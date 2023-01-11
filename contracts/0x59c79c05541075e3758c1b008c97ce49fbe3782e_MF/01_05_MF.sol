// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MandoFan
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//    Everyone knows Mando is the brains of the operation & we are tired of OSF getting all the love.Celebrate Mando's big brain    //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MF is ERC1155Creator {
    constructor() ERC1155Creator("MandoFan", "MF") {}
}