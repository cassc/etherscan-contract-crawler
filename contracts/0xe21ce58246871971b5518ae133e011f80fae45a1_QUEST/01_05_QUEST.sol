// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alchemic Quest
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    Embark upon a perilous journey to the Elixir of the Sages,                //
//    where one misstep may cause the forfeiture of all you have worked for.    //
//    The ultimate NFT quest.                                                   //
//                                                                              //
//    Follow the Mystagogue:                                                    //
//    burn, swap, airdrop, claim                                                //
//    A new type of narrative game                                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract QUEST is ERC1155Creator {
    constructor() ERC1155Creator("Alchemic Quest", "QUEST") {}
}