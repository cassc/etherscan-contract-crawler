// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emblem Vault [Ethereum]
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                //
//                                                                                                                                                                //
//    Emblem Vaults are NFT containers that can contain one or more tokens, or NFT's                                                                              //
//                                                                                                                                                                //
//        Projects : Rare Pepe🐸 | Twitter Eggs🥚 | Sarutobi Island 🐵🏝️ | Spells of Genesis | Bitcorns | Ether Rocks | Etheria (0xb21f8) | Age of Chains👽 *    //
//            Year : [2014 | 2015 | 2016 | 2017 | 2018 Series: 1 | 2 | 3 | 4 | 5 | >5Circulating ↓101 | 100 ↔ 500 | ↑ 500                                         //
//            Guides Counterparty Guide                                                                                                                           //
//                                                                                                                                                                //
//                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EmblemVauItEthereum is ERC721Creator {
    constructor() ERC721Creator("Emblem Vault [Ethereum]", "EmblemVauItEthereum") {}
}