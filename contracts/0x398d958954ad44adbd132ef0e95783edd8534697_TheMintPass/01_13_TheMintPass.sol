// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract TheMintPass is ERC721URIStorage, Ownable {
    uint public tokenCounter;
    bool public isWLMintOpen = false;
    bool public isMintOpen = false;

    uint public constant mintPrice = 0.09 ether;
    uint public constant maxSupply = 4444;
    uint public constant maxMint = 3;

    bytes32 public merkleRoot;

    mapping(address => bool) private isWLMinted;
    mapping(address => bool) private isMinted;
    string private baseURI;

    constructor() ERC721('TheMintPass', 'TMP') {
        tokenCounter = 0;
    }

    function openWLMint(bool _isWLMintOpen) external onlyOwner {
        isWLMintOpen = _isWLMintOpen;
    }

    function openMint(bool _isMintOpen) external onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setWhiteList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function createWLToken(uint numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(isWLMintOpen, 'The white list mint is not open.');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "This address is not in the whitelist.");
        require(numberOfTokens <= maxMint, 'Exceeded max token purchase.');
        require(isWLMinted[msg.sender] == false, 'This address has already mint.');
        require(tokenCounter + numberOfTokens <= maxSupply, 'Purchase would exceed max tokens.');
        require(msg.value >= mintPrice * numberOfTokens, 'Ether value send is not correct.');

        for (uint i = 0; i < numberOfTokens; i++) {
            tokenCounter++;
            _safeMint(msg.sender, tokenCounter);
            _setTokenURI(tokenCounter, baseURI);
        }
        isWLMinted[msg.sender] = true;
    }

    function createToken(uint numberOfTokens) external payable {
        require(isMintOpen, 'The mint is not open.');
        require(isMinted[msg.sender] == false, 'This address has already mint.');
        require(numberOfTokens <= maxMint, 'Exceeded max token purchase.');
        require(tokenCounter + numberOfTokens <= maxSupply, 'Purchase would exceed max tokens.');
        require(msg.value >= mintPrice * numberOfTokens, 'Ether value send is not correct.');

        for (uint i = 0; i < numberOfTokens; i++) {
            tokenCounter++;
            _safeMint(msg.sender, tokenCounter);
            _setTokenURI(tokenCounter, baseURI);
        }
        isMinted[msg.sender] = true;
    }

    function reserve(uint n) external onlyOwner {
        require(tokenCounter + n <= maxSupply, 'Purchase would exceed max tokens.');
        for (uint i = 0; i < n; i++) {
            tokenCounter++;
            _safeMint(msg.sender, tokenCounter);
            _setTokenURI(tokenCounter, baseURI);
        }
    }

    function totalSupply() public view returns (uint) {
        return tokenCounter;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }
}