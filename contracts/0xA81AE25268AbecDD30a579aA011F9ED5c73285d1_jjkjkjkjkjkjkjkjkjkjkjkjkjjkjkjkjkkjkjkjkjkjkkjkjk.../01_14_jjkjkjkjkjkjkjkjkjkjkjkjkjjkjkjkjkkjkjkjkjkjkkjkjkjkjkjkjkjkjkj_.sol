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


contract jjkjkjkjkjkjkjkjkjkjkjkjkjjkjkjkjkkjkjkjkjkjkkjkjkjkjkjkjkjkjkj_ is GMERC721A {

    PreSaleInfo public _preSaleInfo = PreSaleInfo(
        true,
        1660299000,
        1660299300,
        100000000000000,
        1,
        10,
        false
    );
    
    PublicSaleInfo public _publicSaleInfo = PublicSaleInfo(
        1660299600,
        1660299900,
        100000000000000,
        1
    );
    address[]  _receivers  = [0x6EB2bfe08DA170d18F7ED7B27Ec28b23fc69cEF2];
    uint256[] _basisPoints  = [600];


    constructor(
    ) GMERC721A(
        unicode"jjkjkjkjkjkjkjkjkjkjkjkjkjjkjkjkjkkjkjkjkjkjkkjkjkjkjkjkjkjkjkj",
        unicode"nihao",
        "https://api.nftgm.art/api/v1/nftgm/metadata/eth/62f624d0caadf459c54893af/",
        10,
        0x6EB2bfe08DA170d18F7ED7B27Ec28b23fc69cEF2,
        _preSaleInfo,
        _publicSaleInfo,
        _receivers,
        _basisPoints
    ) {
    }
}