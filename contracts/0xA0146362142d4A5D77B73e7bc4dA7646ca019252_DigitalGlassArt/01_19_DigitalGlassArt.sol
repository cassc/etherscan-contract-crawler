// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@bits/ethereum/contracts/tokens/Token.sol";

contract DigitalGlassArt is Token {
    address[] private mintPayees = [
        0x76d7aFBaF00f066FbF32F42dbC11F60F69bBaC12,
        0x4212eA213B88545b2e12Db5271F0f336BE605053,
        0xE4dF76459a47b599cE7d8F26205543Fd2F446e6A,
        0xa61a895de7e6D6a592E30674121a330969Abf925,
        0xD3207315C9E5a54174921037809DC3a76a0b0564,
        0x57Fd1BE7a01C0ee40A755c1651aC6e9E38B2fcc3,
        0x9E0926D846545928529F11432694d840149af942,
        0x6E3D145927d17E13F5c241ecB58E7EC87f61a799,
        0xd2Bd63C9f0a80DCDfc371B4C6b237d095a226384,
        0x5c83175435EB5Ad1E0177f54955E86081EEf2e83,
        0x1A441c4daE91b29cab0Ad8f6E1D0119aF21Dcc3d,
        0x55D9693f2545bFba8cF535d4bCD2f984758BfF43,
        0x7C59597bD10b02583EE9A818D6AbaE0C8A02a640,
        0x4a431456E5Ed1630ccA2dD1e561852cf0f26Dc19,
        0xB3BA7449Fe98Ee2da95cF1cbb01727c999870579,
        0xC0d2C3958B19E0F7780a56e547a5F0f714c3bDDa,
        0x6c8373C7a66337e293192b020d82Af1Fe0c852a6,
        0x443881f8A420968F9CC80b431754824235020ddD,
        0xc42bF75802d1d5FE603327baBF78234D362Aa07d,
        0x312d629a18BB74f62c9a36a77Ebe64f9c2C31f79,
        0x8D1aE9B102872780Df227468d15236A7724057cD,
        0x3A5EfFb54941186522107C474cAF3e626132F2d4,
        0xDFB770C0719E4C9C32C40426E7C987c36825Cad8,
        0x18481Dd8b5D5f81f9E05E4Ce245dc7E365A05648,
        0x1105C6c2B1d88Cb1648b73B41DE701009EdC9747,
        0x7eDc54ae00FB4Be6FeB4Ae04D7d89a6E597704A9,
        0xD383C5fF514272929113c64bdB7E2CfbCda2793e,
        0xAD5FeB62444d0e6E10890C6577c1579FF2caa2E1,
        0x83da76b75F7ddD4B434E1faf2490d465D6b471e6,
        0x7cF5dB1a6372F2A59DeC83E404eda90bEC504abf,
        0x1b6c33a0298DCBAa63317778E6a181d8024c2263,
        0x5DCdb939aeE775616bca5c529da158e5CDaE11eF,
        0xC10755ee7044DE16FAbf6273D90038d7028F55A5,
        0x825E0E1a6DBE30B79f4eE8A4a38a9dE310cF8553,
        0xBA3b75850F07e86d7C82C6172E0D2877911adE34,
        0xdd13c843013BF1115fAB4Cc3ae2193b0213ACDb1,
        0x4BB532E6e0c99CAe6848Cf916c45E0A9E7e45ebD,
        0x9cdF79F3F0244264a54C582CCf402C081ee9eb8A,
        0x7Dc9609a0E65f7dD6331a0f0071535D9221A96c4
    ];

    uint256[] private mintShares = [
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        60,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        60,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        40,
        60,
        300,
        1180,
        720
    ];

    function royaltyInfo(uint256, uint256 salePrice) external view override 
        returns (address receiver, uint256 royaltyAmount) {
        return (address(this), salePrice * 10 / 100);
    }

    constructor(
        string memory baseUri,
        bool _saleActive,
        bool _presaleActive,
        address[] memory _presaleAddresses, 
        uint256[] memory _presaleClaims
    )
    ERC721("Digital Glass Art", "DGA")
    Token(
        baseUri,
        mintPayees,
        mintShares,
        333,
        10,
        0.1 ether,
        0.077 ether,
        _saleActive,
        _presaleActive,
        _presaleAddresses, 
        _presaleClaims
    ) {}
}