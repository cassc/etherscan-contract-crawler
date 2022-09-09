// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract HybridHumans is ERC721A, Ownable {
    // errors
    error NotEnoughTokens();
    error ExceedMaxMint();
    error InvalidProof(bytes32[] proof);
    error WrongValueSent();
    error SaleIsPaused();

    // constants
    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant BULK_MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_PER_PUBLIC_WALLET = 10;
    uint256 public constant MAX_PER_WHITELIST_WALLET = 5;

    bytes32 private merkleRoot;
    string private baseTokenURI;
    bool private isRevealed;
    address private HYBRID_HUMANS_TREASURY = 0xc9Bfb7a0607a5670bb77c5fc2D72c86941ED2EF9;

    bool public publicSaleStarted;

    mapping(address => bool) public whaleMinter;

    constructor(bytes32 _root, address[] memory _whales, string memory _baseTokenURI) ERC721A("Hybrid Humans", "HyHu") {
        for (uint256 i = 0; i < _whales.length;) {
            whaleMinter[_whales[i]] = true;
            unchecked { i++; }
        }

        merkleRoot = _root;
        baseTokenURI = _baseTokenURI;
        _mint(HYBRID_HUMANS_TREASURY, 200);
    }

    function mintWhitelist(bytes32[] calldata _proof, uint256 amount) external payable {
        if (!whaleMinter[msg.sender] && _numberMinted(msg.sender) + amount > MAX_PER_WHITELIST_WALLET) revert ExceedMaxMint();

        uint256 price = amount > MAX_PER_WHITELIST_WALLET ? BULK_MINT_PRICE : MINT_PRICE;

        if (msg.value != price * amount) revert WrongValueSent();

        bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));

        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
            revert InvalidProof(_proof);
        }

        _mint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        if (!publicSaleStarted) revert SaleIsPaused();
        if (!whaleMinter[msg.sender] && _numberMinted(msg.sender) + amount > MAX_PER_PUBLIC_WALLET) revert ExceedMaxMint();

        uint256 price = amount > MAX_PER_WHITELIST_WALLET ? BULK_MINT_PRICE : MINT_PRICE;

        if (msg.value != price * amount) revert WrongValueSent();

        _mint(msg.sender, amount);
    }

    function startPublicSale() external onlyOwner {
        publicSaleStarted = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealed) return _baseURI();

        return super.tokenURI(tokenId);
    }

    function setRevealed(string calldata _baseTokenURI) external onlyOwner {
        setBaseTokenURI(_baseTokenURI);
        isRevealed = true;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }


    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}