// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IContractNFT {
    struct NFTProducts {
        string name;
        uint256 busdprice;
        uint256 fuel;
        string tokenuri;
    }

    function ownerOf(uint256 tokenId) external view returns (address);
    function getTokenData(uint256 tokenID) external view returns (NFTProducts memory);
}