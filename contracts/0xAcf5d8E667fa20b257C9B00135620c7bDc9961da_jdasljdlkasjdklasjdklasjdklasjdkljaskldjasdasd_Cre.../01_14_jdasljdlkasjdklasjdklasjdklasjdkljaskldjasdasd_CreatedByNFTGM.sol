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


contract jdasljdlkasjdklasjdklasjdklasjdkljaskldjasdasd_CreatedByNFTGM is GMERC721A {

    PreSaleInfo public _preSaleInfo = PreSaleInfo(
        true,
        1660300500,
        1660300800,
        100000000000000,
        1,
        1,
        true
    );
    
    PublicSaleInfo public _publicSaleInfo = PublicSaleInfo(
        1660301100,
        1660301400,
        100000000000000,
        1
    );
    address[]  _receivers  = [0x6EB2bfe08DA170d18F7ED7B27Ec28b23fc69cEF2];
    uint256[] _basisPoints  = [5000];


    constructor(
    ) GMERC721A(
        unicode"jdasljdlkasjdklasjdklasjdklasjdkljaskldjasdasd",
        unicode"jjjjjjjjjjjjjjjdddddddddddddddd",
        "https://api.nftgm.art/api/v1/nftgm/metadata/eth/62f62b87caadf459c54893c4/",
        10,
        0x6EB2bfe08DA170d18F7ED7B27Ec28b23fc69cEF2,
        _preSaleInfo,
        _publicSaleInfo,
        _receivers,
        _basisPoints
    ) {
    }
}