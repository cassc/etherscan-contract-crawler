// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE Music NFT - AI The Artist Feat. Not Drake & Not Kanye [On ETH]
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    We are all one sound - AI The Artist    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract PEPE is ERC1155Creator {
    constructor() ERC1155Creator("PEPE Music NFT - AI The Artist Feat. Not Drake & Not Kanye [On ETH]", "PEPE") {}
}