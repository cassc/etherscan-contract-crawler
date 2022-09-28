// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NounDickButt is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private preRevealUri;
    string private baseTokenUri;

    uint256 public saleStatus = 0;

    bool public revealed;

    // ------ Sale Settings
    uint256 private constant PRICE_PUBLIC_NOUNDICKBUTT = 0.005 ether;
    uint256 private constant MAX_NOUNDICKBUTT = 4666;
    uint256 private constant DEPLOYER_RESERVED = 150;
    uint256 private constant LIMIT_PER_TXN = 20;

    mapping(address => uint256) public claimedNounButt;

    constructor(string memory _preRevealUri) ERC721A("NounDickButt", "NOUNDICKBUTT") {
        preRevealUri = _preRevealUri;
        _mint(tx.origin, DEPLOYER_RESERVED);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 _amount) external payable callerIsUser {
        require(saleStatus > 0, "Sale is not active");
        require(_amount <= LIMIT_PER_TXN, "Exceeds limit per txn");
        require(msg.value >= PRICE_PUBLIC_NOUNDICKBUTT * _amount, "Insufficient ETH sent");
        require(totalSupply() + _amount <= MAX_NOUNDICKBUTT, "Exceeds max supply");
        _safeMint(msg.sender, _amount);
    }

    function reveal(bool _reveal) external onlyOwner {
        revealed = _reveal;
    }

    function setSaleStatus(uint256 _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return preRevealUri;
        return string(abi.encodePacked(baseTokenUri, _tokenId.toString()));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenUri = baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}