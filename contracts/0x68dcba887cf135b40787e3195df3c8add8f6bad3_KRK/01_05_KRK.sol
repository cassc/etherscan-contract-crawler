// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTO 4RT STUDIES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    The collection is based on the concept of bringing together two different worlds               //
//    The world of fantasy and the world of cryptocurrency.                                          //
//                                                                                                   //
//    All the pieces in this collection are created using digital painting techniques,               //
//    which allows for a high degree of flexibility and creativity in the design process.            //
//    Each NFT is a unique work of art, featuring a one-of-a-kind fantastical character that         //
//    is brought to life through the digital medium.                                                 //
//                                                                                                   //
//    By owning one of these unique and valuable pieces, you will not only be supporting my work,    //
//    but you will also be investing in the future of digital art and cryptocurrency.                //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract KRK is ERC721Creator {
    constructor() ERC721Creator("CRYPTO 4RT STUDIES", "KRK") {}
}