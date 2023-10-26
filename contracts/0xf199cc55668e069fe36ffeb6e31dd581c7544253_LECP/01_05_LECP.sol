// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOW EFFORT COLLAGE PUNKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                            //
//                                                                                                                                                            //
//    This collection is a tribute to Low effort Punks (LEP), created by the community for the community, each punk is remade by DCOT aKa CollagePunks.ᵍᵐ     //
//    the punks that here were requested by their owners.                                                                                                     //
//    DCOT is just doing a cult reinterpretation of internet PUNK culture.                                                                                    //
//    some tokens will be migrated from the genesis collection                                                                                                //
//    https://polygonscan.com/token/0xf030c1cFa7872Bf58a86BA685438E062436cB5E7                                                                                //
//    BY DCOT.                                                                                                                                                //
//                                                                                                                                                            //
//    BUY PUNK!                                                                                                                                               //
//                                                                                                                                                            //
//                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LECP is ERC721Creator {
    constructor() ERC721Creator("LOW EFFORT COLLAGE PUNKS", "LECP") {}
}