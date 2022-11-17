// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Avinro's claims
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    In this contract, all collector will be able to claims my airdrops for them.    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract AVCLMS is ERC721Creator {
    constructor() ERC721Creator("Avinro's claims", "AVCLMS") {}
}