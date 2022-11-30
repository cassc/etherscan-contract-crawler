// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blockheads
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//     Blockheads are one of worlds most early NFT avatars (2014/15) on the Namecoin Blockchain.    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract Blockheads is ERC721Creator {
    constructor() ERC721Creator("Blockheads", "Blockheads") {}
}