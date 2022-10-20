// SPDX-License-Identifier: MIT
// Top Dog Studios 0.1
//  Allows users to list their assetss across OpenSea and LooksRare
//  without spending gas (approving the collection for trading)
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry { mapping(address => OwnableDelegateProxy) public proxies; }

abstract contract ERC721APreapproved is ERC721A, Ownable {
    address private immutable _openSeaProxyRegistryAddress;
    address private immutable _looksRareTransferManagerAddress;
    bool private _isMarketplacesApproved = true;

    constructor (
        string memory name,
        string memory symbol,
        address openSeaProxyRegistryAddress,
        address looksRareTransferManagerAddress
    ) ERC721A(name, symbol) {
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
        _looksRareTransferManagerAddress = looksRareTransferManagerAddress;
    }

    function setMarketplacesApproved(bool isMarketplacesApproved) external onlyOwner {
        _isMarketplacesApproved = isMarketplacesApproved;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
        if (_isMarketplacesApproved && (address(proxyRegistry.proxies(owner)) == operator))
            return true;

        return super.isApprovedForAll(owner, operator);
    }
}