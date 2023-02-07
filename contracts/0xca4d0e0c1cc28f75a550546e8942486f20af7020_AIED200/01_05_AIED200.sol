// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 200 DAYS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    First 200 Days of borovik's AIED (AI Everday) collection. Started July 12th 2022.           //
//    borovik has created and minted 1 NFT each day. This OE will be burnable for future NFTs.    //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIED200 is ERC1155Creator {
    constructor() ERC1155Creator("200 DAYS", "AIED200") {}
}