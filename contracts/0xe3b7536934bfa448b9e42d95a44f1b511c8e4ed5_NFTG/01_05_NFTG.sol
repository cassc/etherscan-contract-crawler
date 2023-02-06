// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Introducing the AI NFT Girl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    Meet AI Girl                                      //
//    the one-of-a-kind AI-generated NFT character      //
//    She is the creation of cutting-edge technology    //
//    designed to be unique and captivating.            //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract NFTG is ERC721Creator {
    constructor() ERC721Creator("Introducing the AI NFT Girl", "NFTG") {}
}