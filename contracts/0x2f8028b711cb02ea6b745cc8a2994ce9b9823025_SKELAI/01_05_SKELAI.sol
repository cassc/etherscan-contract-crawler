// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SKELE-AI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    A digital artist whose work combines the complex algorithms of                       //
//    artificial intelligence with the raw, emotive power of the human form.               //
//    Using cutting-edge technology, Sheikh creates stunning, one-of-a-kind artworks       //
//    that blur the lines between man and machine.                                         //
//                                                                                         //
//    With a style that is both futuristic and deeply human, Sheikh's art is a true        //
//    testament to the endless possibilities of the digital age.                           //
//                                                                                         //
//    Whether through intricate abstract compositions or hyper-realistic portraits,        //
//    Sheikh's work always manages to captivate and inspire its viewers.                   //
//    As an artist working with non-fungible tokens (NFTs), Sheikh is at the forefront     //
//    of a new art movement that is changing the way we think about art, ownership,        //
//    and value.                                                                           //
//                                                                                         //
//    If you're looking for a piece of art that is truly unique and forward-thinking,      //
//    look no further.                                                                     //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract SKELAI is ERC1155Creator {
    constructor() ERC1155Creator("SKELE-AI", "SKELAI") {}
}