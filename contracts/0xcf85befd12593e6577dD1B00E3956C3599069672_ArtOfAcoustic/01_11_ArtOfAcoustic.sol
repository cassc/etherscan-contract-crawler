// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// ▄▀█ █▀█ ▀█▀   █▀█ █▀▀   ▄▀█ █▀▀ █▀█ █░█ █▀ ▀█▀ █ █▀▀
// █▀█ █▀▄ ░█░   █▄█ █▀░   █▀█ █▄▄ █▄█ █▄█ ▄█ ░█░ █ █▄▄

import "./ERC721A.sol";
import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ArtOfAcoustic is ERC721A, Ownable, RevokableDefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 1001;
    uint256 public MINT_PRICE = .004 ether;
    uint256 public MAX_PER_WALLET = 5;
    bool public paused = true;
    string public baseURI;

    constructor(string memory baseURI_) ERC721A("Art of Acoustic", "AOA") {
        baseURI = baseURI_;
    }

    function mint(uint256 _quantity) external payable {
        require(!paused, "The contract is paused!");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Not enough tokens left!"
        );
        require(_quantity <= MAX_PER_WALLET, "You cannot mint more than 5 Tokens at once!");
        require(msg.value >= (MINT_PRICE * _quantity), "Inconsistent amount sent!");

        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(address receiver, uint256 mintAmount) external onlyOwner {
        _safeMint(receiver, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setStatus(uint256 newAmount) external onlyOwner {
        MAX_SUPPLY = newAmount;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        MINT_PRICE = newPrice;
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed");
    }
}