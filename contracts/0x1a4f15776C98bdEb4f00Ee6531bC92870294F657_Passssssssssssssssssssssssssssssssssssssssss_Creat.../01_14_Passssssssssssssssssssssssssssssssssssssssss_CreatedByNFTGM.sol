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



contract Passssssssssssssssssssssssssssssssssssssssss_CreatedByNFTGM is GMERC721A {

    PreSaleInfo public _preSaleInfo = PreSaleInfo(
        true,
        1660255200,
        1660297500,
        100000000000000,
        2,
        5,
        true
    );
    
    PublicSaleInfo public _publicSaleInfo = PublicSaleInfo(
        1660297800,
        1660298400,
        100000000000000,
        2
    );
    address[]  _receivers  = [0x6EB2bfe08DA170d18F7ED7B27Ec28b23fc69cEF2, 0x6EB2bfe08DA170d18F7ED7B27Ec28b23fc69cEF2];
    uint256[] _basisPoints  = [500, 300];


    constructor(
    ) GMERC721A(
        unicode"Passssssssssssssssssssssssssssssssssssssssss",
        unicode"pssssssssssssssssssssssssssssssssssssssss",
        "https://api.nftgm.art/api/v1/nftgm/metadata/eth/62f61c8bde7533abc448b65f/",
        10,
        0x6EB2bfe08DA170d18F7ED7B27Ec28b23fc69cEF2,
        _preSaleInfo,
        _publicSaleInfo,
        _receivers,
        _basisPoints
    ) {
    }
}