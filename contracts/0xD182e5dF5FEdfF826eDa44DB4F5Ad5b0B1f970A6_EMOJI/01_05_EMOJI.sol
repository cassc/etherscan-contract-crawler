// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Federal Court Emojis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//    A federal court judge ruled that these emojis 🚀📈💰objectively mean "one thing: a financial return on investment."          //
//                                                                                                                                 //
//    Users of these emojis are hereby warned of the legal consequence of their use. #emojis                                       //
//                                                                                                                                 //
//    The purchaser of this NFT hereby acknowledges that price will likely go to zero, despite the use of 🚀📈💰.                  //
//                                                                                                                                 //
//    The purchaser of the NFT is acquiring the art only to collect a meme for fun, and not for any sort of investment purpose.    //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EMOJI is ERC1155Creator {
    constructor() ERC1155Creator("Federal Court Emojis", "EMOJI") {}
}