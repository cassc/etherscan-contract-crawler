// SPDX-License-Identifier: MIT

/// @title ERC721Tradable
///
/// An ERC721 contract that whitelists the OpenSea Proxy for easy listing & trading and allows us to set contract-wide royalty information.
///
/// Based on work done originally by Dynamic Culture
/// https://github.com/Dynamiculture/neurapunks-contract/blob/d250e955453773566ba54e64fdea39ee221bc3d4/contracts/ERC721Tradable.sol

pragma solidity 0.8.7;

import { ERC721 } from "./ERC721.sol";
import { ERC721URIStorage } from "./ERC721URIStorage.sol";
import { ERC2981ContractWideRoyalties, ERC2981Royalties } from "./ERC2981ContractWideRoyalties.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Tradable is 
    ERC721URIStorage,
    ERC2981ContractWideRoyalties 
{

    // OpenSea's Proxy Registry
    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981Royalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}