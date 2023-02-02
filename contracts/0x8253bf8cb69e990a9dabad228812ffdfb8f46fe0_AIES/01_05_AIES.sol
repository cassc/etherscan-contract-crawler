// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AliensInsideEearth S
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//    The NFT of Earth Center Man series of confirmed assets is cast by the Lian Shang Entertainment Web3 Foundation based on the Ethereum chain. Holders of this NFT can enjoy a monthly dividend of 10%    //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIES is ERC721Creator {
    constructor() ERC721Creator("AliensInsideEearth S", "AIES") {}
}