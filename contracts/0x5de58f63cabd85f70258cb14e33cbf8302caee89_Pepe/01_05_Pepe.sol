// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe El Raro
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    Pepe El Raro NFTs created by 0xNFTsHUSTLE     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Pepe is ERC721Creator {
    constructor() ERC721Creator("Pepe El Raro", "Pepe") {}
}