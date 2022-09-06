// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/////////////////////////////////////////////////////////
//    all-in-one NFT generator at https://nftgm.art    //
/////////////////////////////////////////////////////////

import "@nftgm/GMERC721A.sol";


/////////////////////////////////////////////////////
//   __    _  _______  _______  _______  __   __   //
//  |  |  | ||       ||       ||       ||  |_|  |  //
//  |   |_| ||    ___||_     _||    ___||       |  //
//  |       ||   |___   |   |  |   | __ |       |  //
//  |  _    ||    ___|  |   |  |   ||  ||       |  //
//  | | |   ||   |      |   |  |   |_| || ||_|| |  //
//  |_|  |__||___|      |___|  |_______||_|   |_|  //
/////////////////////////////////////////////////////


contract hhhh_CreatedByNFTGM is GMERC721A {

    PreSaleInfo public _preSaleInfo = PreSaleInfo(
        true,
        1660643030,
        1660729433,
        10000000000000000,
        1,
        10,
        false
    );
    
    PublicSaleInfo public _publicSaleInfo = PublicSaleInfo(
        1660815843,
        1660902246,
        100000000000000000,
        1
    );
    address[]  _receivers  = [0xA6eAE4aaf57bb9B002032855449f706b1EbE1253];
    uint256[] _basisPoints  = [1000];


    constructor(
    ) GMERC721A(
        unicode"hhhh",
        unicode"aaaaa",
        "https://api.nftgm.art/api/v1/nftgm/metadata/eth/62fb6767329d161a96f94b63/",
        10,
        0xA6eAE4aaf57bb9B002032855449f706b1EbE1253,
        _preSaleInfo,
        _publicSaleInfo,
        _receivers,
        _basisPoints
    ) {
    }
}