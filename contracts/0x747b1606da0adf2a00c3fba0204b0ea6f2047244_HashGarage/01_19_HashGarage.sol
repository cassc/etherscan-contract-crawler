// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Tradable.sol";

/**
 * @title HashGarage
 * HashGarage - a contract for my non-fungible cars.
 */
contract HashGarage is ERC721Tradable {
    // contract Ape is ERC721Tradable, Ownable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("HashGarage", "HGS", _proxyRegistryAddress)
    {}

    function baseTokenURI() public override pure returns (string memory) {
        return "https://hashgarage.com/api/metadata/cars/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://hashgarage.com/api/metadata/contract";
    }

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }
}