// SPDX-License-Identifier: MIT
// Created by Yu-Chen Song on 2023/1/03 https://www.linkedin.com/in/yu-chen-song-08892a77/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IFactoryERC721PayWithEther.sol";

contract ERC721PayWithEther is IFactoryERC721PayWithEther, Ownable, ERC721Enumerable {

    uint256 public constant MAX_TOTAL_TOKEN_MINT = 168;

    uint256 public latestMintedId;

    uint256 public constant PRICE = 0.02 ether;

    bool private isMetadataFrozen = false;
    string private contractDataURI;
    string private metadataURI;

    event Withdraw(address _address, uint256 balance);
    event SetContractDataURI(string _contractDataURI);
    event SetURI(string _uri);
    event MetadataFrozen();
    event Mint(address _address, uint256 tokenId);
    event Redeem(address _address, uint256 tokenId);

    constructor(string memory _contractDataURI, string memory _uri) ERC721("Demi Trader", "DT") {
        require(keccak256(abi.encodePacked(_contractDataURI)) != keccak256(abi.encodePacked("")), "init from empty uri");
        require(keccak256(abi.encodePacked(_uri)) != keccak256(abi.encodePacked("")), "init from empty uri");
        contractDataURI = _contractDataURI;
        metadataURI = _uri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(metadataURI, Strings.toString(_tokenId), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return contractDataURI;
    }

    function setContractDataURI(string memory _contractDataURI) external onlyOwner {
        contractDataURI = _contractDataURI;
        emit SetContractDataURI(_contractDataURI);
    }

    function setURI(string memory _uri) external onlyOwner {
        require(!isMetadataFrozen, "URI Already Frozen");
        metadataURI = _uri;
        emit SetURI(_uri);
    }

    function metadataFrozen() external onlyOwner {
        isMetadataFrozen = true;
        emit MetadataFrozen();
    }

    function withdraw(address _address, uint256 _amount) external override onlyOwner {
        require(totalSupply() == 0 && _amount > 0, "TotalSupply is not 0 or amount cannot be 0");
        require(payable(_address).send(_amount), "Fail to withdraw");
        emit Withdraw(_address, _amount);
    }

    function redeem(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "You not own this token id");
        require(payable(msg.sender).send(PRICE), "Fail to withdraw");
        _burn(tokenId);
        emit Redeem(msg.sender, tokenId);
    }

    function batchRedeem(uint256[] memory tokenIds) external override {
        uint256 amount = tokenIds.length;
        require(amount > 0, "Amount cannot be 0");
        require(payable(msg.sender).send(PRICE * amount), "Fail to withdraw");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "You not own this token id");
            _burn(tokenId);
            emit Redeem(msg.sender, tokenId);
        }
    }

    function _mint() external payable override canMint(MAX_TOTAL_TOKEN_MINT) onlyOwner {
        uint256 amount = MAX_TOTAL_TOKEN_MINT * PRICE;
        require(amount <= msg.value, "Sent value is not enough");

        uint256 id = latestMintedId + 1;

        latestMintedId += MAX_TOTAL_TOKEN_MINT;

        for (uint256 i = 0; i < MAX_TOTAL_TOKEN_MINT; i++) {
            _safeMint(msg.sender, id + i);
            emit Mint(msg.sender, id + i);
        }
    }

    function _transfer(address[] memory tos, uint256[] memory tokenIds) external override onlyOwner {
        require(tos.length == tokenIds.length, "Receivers and IDs are different length");

        for (uint256 i = 0; i < tos.length; i++) {
            safeTransferFrom(msg.sender, tos[i], tokenIds[i]);
        }
    }

    modifier canMint(uint256 _amount) {
        require(_amount > 0, "Number tokens cannot be 0");
        require(latestMintedId + _amount <= MAX_TOTAL_TOKEN_MINT, "Over maximum minted amount");
        _;
    }
}