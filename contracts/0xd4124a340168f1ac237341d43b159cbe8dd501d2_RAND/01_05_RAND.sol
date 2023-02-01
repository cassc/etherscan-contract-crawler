// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sebastien Alain Gaston Rouxel An - Random
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    This collection features the works of Sebastien Alain Gaston Rouxel,          //
//    also known as NFTech. It showcases a diverse range of his creations,          //
//    including paintings, conceptual pieces, and photography,                      //
//    that are not part of any particular series.                                   //
//                                                                                  //
//    Verified by previous address (0xbAc89cB9BEfe09C226bB7003869642B7A0550988):    //
//    https://etherscan.io/verifySig/13904                                          //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract RAND is ERC1155Creator {
    constructor() ERC1155Creator("Sebastien Alain Gaston Rouxel An - Random", "RAND") {}
}