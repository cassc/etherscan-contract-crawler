// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC721Royalty, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

contract CustomCollection is ERC721Royalty, Ownable, DefaultOperatorFilterer {
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
    ) ERC721(name_, ticker_) DefaultOperatorFilterer() Ownable() {
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

    /// Overrides
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
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