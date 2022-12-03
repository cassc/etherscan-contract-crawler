// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// @title:  Ancient Perception
// @desc:   An evocative collection of 30 1/1 photography NFTs by the Italian photographer Simone Risi
// @artist: https://www.instagram.com/bysimonerisi
// @author: https://medusa.dev
// @url:    https://simonerisi.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract AncientPerception is
    Ownable,
    ERC721Enumerable,
    IERC2981,
    ReentrancyGuard
{
    event PublicSaleEnabled();
    event SaleEnded();
    event TokenMinted(uint256);
    event Redeem(uint256);

    uint256 private constant MAX_SUPPLY = 30;
    mapping(uint256 => address) private _redeem;

    uint256 public constant MINT_COST = 0.25 ether;
    bool public isMetadataLocked;
    bool public isPublicSale;
    bool public hasSaleEnded;
    address public royaltyReceiver;
    uint256 public royaltyPercentage;
    string public baseURI;

    constructor(string memory baseURI_) ERC721("AncientPerception", "ANPE") {
        baseURI = baseURI_;
        royaltyReceiver = owner();
        royaltyPercentage = 700;
    }

    function enablePublicSale() external onlyOwner {
        require(!hasSaleEnded, "Sale ended");
        isPublicSale = true;
        emit PublicSaleEnabled();
    }

    function mint(uint256 tokenId) external payable nonReentrant {
        require(!hasSaleEnded, "Sale ended");
        require(isPublicSale, "Public sale is not enabled");
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(
            tokenId > 0 && tokenId <= MAX_SUPPLY,
            "Token ID not in right interval"
        );
        require(msg.value >= MINT_COST, "Not enough ETH");

        if (totalSupply() + 1 == MAX_SUPPLY) {
            isPublicSale = false;
            hasSaleEnded = true;
            emit SaleEnded();
        }

        if (msg.value > MINT_COST) {
            payable(msg.sender).transfer(msg.value - MINT_COST);
        }

        _safeMint(msg.sender, tokenId);
        emit TokenMinted(tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function lockMetadata() external onlyOwner {
        require(!isMetadataLocked, "Metadata are already locked");
        isMetadataLocked = true;
    }

    function isRedeemed(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Invalid token ID");
        return _redeem[tokenId] != address(0);
    }

    function getRedeemer(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Invalid token ID");
        return _redeem[tokenId];
    }

    function redeem(uint256 tokenId) external {
        require(_exists(tokenId), "Invalid token ID");
        require(_redeem[tokenId] == address(0), "Already redeemed");
        require(msg.sender == ownerOf(tokenId), "Only owner can redeem");
        _redeem[tokenId] = msg.sender;
        emit Redeem(tokenId);
    }

    function redeem(uint256 tokenId, address redeemer) external onlyOwner {
        require(_exists(tokenId), "Invalid token ID");
        require(_redeem[tokenId] == address(0), "Already redeemed");
        require(redeemer == ownerOf(tokenId), "Redeemer is not owner of token");
        _redeem[tokenId] = redeemer;
        emit Redeem(tokenId);
    }

    function deredeem(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Invalid token ID");
        require(_redeem[tokenId] != address(0), "Already not redeemed");
        _redeem[tokenId] = address(0);
    }

    function setRoyaltyReceiver(address royaltyReceiver_) external onlyOwner {
        royaltyReceiver = royaltyReceiver_;
    }

    function setRoyaltyPercentage(
        uint256 royaltyPercentage_
    ) external onlyOwner {
        require(royaltyPercentage_ <= 10000, "Royalty percentage Too high");
        royaltyPercentage = royaltyPercentage_;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Nonexistent token");
        return (royaltyReceiver, (salePrice * royaltyPercentage) / 10000);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(!isMetadataLocked, "Metadata are locked");
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}