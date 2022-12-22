// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAGIRA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    BBBB   AA   GGG  III RRRR   AA      //
//    B   B A  A G      I  R   R A  A     //
//    BBBB  AAAA G  GG  I  RRRR  AAAA     //
//    B   B A  A G   G  I  R R   A  A     //
//    BBBB  A  A  GGG  III R  RR A  A     //
//                                        //
//                                        //
////////////////////////////////////////////


contract BAGI is ERC721Creator {
    constructor() ERC721Creator("BAGIRA", "BAGI") {}
}