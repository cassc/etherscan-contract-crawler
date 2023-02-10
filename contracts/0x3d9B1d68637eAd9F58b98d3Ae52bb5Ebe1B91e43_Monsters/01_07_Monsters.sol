// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Monsters is ERC721A, Ownable {
    string private _baseTokenURI;
    uint256 internal publicMintPrice = 0.0333 ether;
    uint256 internal MAX_SUPPLY = 3333;
    bytes32 private whitelistMerkleRoot = 0xacd396ee820d0ee8da94e54ed6effb5862c652963affbedbae67d8caf8be5e1a;
    bool public isSale = false;
    bool public isPublicSale = false;

    constructor(string memory baseURI) ERC721A("Monsters of Masonry", "MOM") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
        _;
    }

    modifier onlyAuthorized() {
        require(owner() == msg.sender);
        _;
    }

    function toggleSale() public onlyAuthorized {
        isSale = !isSale;
    }

    function togglePublicSale() public onlyAuthorized {
        isPublicSale = !isPublicSale;
    }

    function getCurrentPrice() public view returns (uint256) {
        return publicMintPrice;
    }

    function setBaseURI(string memory baseURI) public onlyAuthorized {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMaxMintSupply(uint256 maxMintSupply) external onlyAuthorized {
        MAX_SUPPLY = maxMintSupply;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRootHash) public onlyAuthorized {
        whitelistMerkleRoot = merkleRootHash;
    }

    function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized saleIsOpen {
        uint256 supply = totalSupply();

        require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");

        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add a null address");
            _safeMint(addresses[i], _count);
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token Id Non-existent");
        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json"))
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _count, bytes32[] calldata _merkleProof, address _address) public payable saleIsOpen {
        uint256 mintIndex = totalSupply();

        if (_address != owner()) {
            require(isSale, "Mint is not available");
            if (!isPublicSale) {
                require(_verifyAddressInWhiteList(_merkleProof, _address), "NFT:Sender is not whitelisted.");
            }
            require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
            require(msg.value >= publicMintPrice * _count, "Insufficient ETH amount sent.");

            uint256 amount = msg.value;
            payable(0xA4087EA6d1De1Dc9f84A8f8d63657cf4AD456817).transfer((amount * 10) / 100);
            payable(0xf25b085D8AFc6BE9eb9b69a4Fa3BC5DFec487510).transfer((amount * 90) / 100);
        }

        _safeMint(_address, _count);
    }

    function _verifyAddressInWhiteList(bytes32[] calldata merkleProof, address toAddress) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(toAddress));
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf);
    }
}