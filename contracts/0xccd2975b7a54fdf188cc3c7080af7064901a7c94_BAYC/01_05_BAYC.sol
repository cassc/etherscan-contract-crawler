// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BoredApeYachtCIub
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//    The Bored Ape Yacht Club is a collection of 10000 unique Bored Ape NFTs— unique digital collectibles living on the Ethereum blockchain.    //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BAYC is ERC721Creator {
    constructor() ERC721Creator("BoredApeYachtCIub", "BAYC") {}
}