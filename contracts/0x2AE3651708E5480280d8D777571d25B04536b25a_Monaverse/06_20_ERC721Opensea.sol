// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract  ERC721Opensea is Ownable, ERC721Enumerable {
    string private _contractURI;
    string private _tokenBaseURI;
    address proxyRegistryAddress;

    constructor() {}

    // https://github.com/ProjectOpenSea/opensea-creatures/blob/74e24b99471380d148057d5c93115dfaf9a1fa9e/migrations/2_deploy_contracts.js#L29
    // rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
    // mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    function setproxyRegistryAddress(address proxyAddress) external onlyOwner {
        proxyRegistryAddress = proxyAddress;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }


    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _tokenBaseURI;
    }
}