// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cautron Storefront
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    Cautron Storefront is a broad-themed contract         //
//    used to showcase NFTs with subjects outside of        //
//    the CautronVerse; which is the digitalization         //
//    community-universe of Cautron Software, which         //
//    researches web3 and digital technologies,             //
//    contributes to its development, produces              //
//    digital assets. We examine the development of the     //
//    virtual universe and, accordingly; the conditions     //
//    and innovations that develop in the real world.       //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract CSTORE is ERC721Creator {
    constructor() ERC721Creator("Cautron Storefront", "CSTORE") {}
}