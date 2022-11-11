// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomCollection is ERC721Royalty, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Minted NFT Count
    Counters.Counter private _nftSupply;

    string private _baseUri;
    uint96 private _royalty;
    uint256 private _maxSupply;

    constructor(
        string memory name_,
        string memory ticker_,
        string memory baseURI_,
        uint96 royalty_,
        uint256 maxSupply_
    ) ERC721(name_, ticker_) {
        _baseUri = baseURI_;
        _royalty = royalty_;
        _maxSupply = maxSupply_;
        _setDefaultRoyalty(msg.sender, royalty_);
    }

    function safeMint(address to, uint256 qty) public onlyOwner {
        uint256 alreadyMinted = Counters.current(_nftSupply);
        require(alreadyMinted + qty <= _maxSupply, "Already Minted Max Amount of NFTs");

        for (uint256 i = 1; i<= qty; i+= 1) {
            uint256 tokenId = alreadyMinted + i;
            _safeMint(to, tokenId);
            Counters.increment(_nftSupply);
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"));
    }

    function updateBaseUri(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function updateRoyaltyReceiver(address receiver_) public onlyOwner {
        _setDefaultRoyalty(receiver_, _royalty);
    }

}