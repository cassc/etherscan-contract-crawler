// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IHashExNFTCertificates {
    struct MintParams {
        address to;
        uint256 id;
    }

    event BaseURIChanged(string oldURI, string newURI);

    function mint(address to, uint256 tokenId) external;

    function setBaseURI(string memory baseURI) external;
}