// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Novaverse is ERC721A, Ownable {

    uint8 private maxTokenPrivate = 2;
    uint8 private maxTokenPublic = 1;

    uint256 public maxTotalSupply = 555;
    uint256 public privateMintPrice = 0.025 ether;
    uint256 public publicMintPrice = 0.027 ether;

    string public baseExtension = ".json";
    string _baseTokenURI;

    enum SaleState{ CLOSED, WL, PUBLIC }
    SaleState public saleState = SaleState.CLOSED;

    bytes32 private merkleRoot;

    mapping(address => uint256) public mintedPrivatePerAddress;
    mapping(address => uint256) public mintedPublicPerAddress;


    constructor() ERC721A("Novaverse Genesis", "NVS") {
        _safeMint(_msgSender(), 55);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function noverselitMint(uint256 amount, bytes32[] calldata proof) public payable {
        require (saleState == SaleState.WL, "Sale is not opened");
        require(mintedPrivatePerAddress[msg.sender] + amount <= maxTokenPrivate, "You can mint a maximum of 2 NFTs");
        require(totalSupply() + amount <= maxTotalSupply, "Max supply reached");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not in the valid whitelist");
        require(amount * privateMintPrice <= msg.value, "Provided not enough Ether for purchase");
        mintedPrivatePerAddress[msg.sender] += amount;
        _safeMint(_msgSender(), amount);
    }

    function publicSale(uint256 amount) public payable {
        require (saleState == SaleState.PUBLIC, "Sale state should be public");
        require(mintedPublicPerAddress[msg.sender] + amount <= maxTokenPublic, "You can mint a maximum of 2 NFTs");
        require(totalSupply() + amount <= maxTotalSupply, "Max supply reached");
        require(amount * publicMintPrice <= msg.value, "Provided not enough Ether for purchase");
        mintedPublicPerAddress[msg.sender] += amount;
        _safeMint(_msgSender(), amount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setSaleState(SaleState newState) public onlyOwner {
        saleState = newState;
    }

    function setPrivateMintPrice(uint256 _privateMintPrice) public onlyOwner {
        privateMintPrice = _privateMintPrice;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) public onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function setMaxTokenPublic(uint8 _maxTokenPublic) public onlyOwner {
        maxTokenPublic = _maxTokenPublic;
    }

    function setMaxTokenPrivate(uint8 _maxTokenPrivate) public onlyOwner {
        maxTokenPrivate = _maxTokenPrivate;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), baseExtension))
        : "";
    }

}