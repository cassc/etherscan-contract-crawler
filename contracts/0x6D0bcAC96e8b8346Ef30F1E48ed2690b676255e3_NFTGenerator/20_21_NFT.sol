//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketplaceAddress;

    constructor(
        address tokenOwner,
        string memory name,
        string memory symbol,
        address _marketplaceAddress
    ) ERC721(name, symbol) {
        _transferOwnership(tokenOwner);
        marketplaceAddress = _marketplaceAddress;
    }

    function createToken(string memory tokenURI) external onlyOwner {
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(marketplaceAddress, true);

        _tokenIds.increment();
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }
}