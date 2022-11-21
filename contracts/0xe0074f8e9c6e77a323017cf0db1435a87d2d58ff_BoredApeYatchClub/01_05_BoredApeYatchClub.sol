// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ape Yatch CIub
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                           //
//    The Bored Ape Yacht Club is a collection of 10,000 unique Bored Ape NFTs— unique digital collectibles living on the Ethereum blockchain. Your Bored Ape doubles as your Yacht Club membership card, and grants access to members-only benefits, the first of which is access to THE BATHROOM, a collaborative graffiti board. Future areas and perks can be unlocked by the community through roadmap activation. Visit www.BoredApeYachtClub.com for more details.    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BoredApeYatchClub is ERC721Creator {
    constructor() ERC721Creator("Bored Ape Yatch CIub", "BoredApeYatchClub") {}
}