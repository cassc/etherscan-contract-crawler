// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketplaceContract;
    event NFTMinted(uint256);

    constructor(address _marketplace) ERC721("MyToken", "MTKN") {
        marketplaceContract = _marketplace;
    }

    function mint(string memory _tokenURI) public returns (uint256) {
         uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        _setTokenURI(newItemId, _tokenURI);
        setApprovalForAll(marketplaceContract, true);
        _tokenIds.increment();
        return _tokenIds.current();
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }
}