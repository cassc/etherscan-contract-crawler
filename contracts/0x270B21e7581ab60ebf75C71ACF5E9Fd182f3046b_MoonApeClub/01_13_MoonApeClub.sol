// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// File: contracts/MoonApeClub.sol

/*
.___  ___.   ______     ______   .__   __.         ___      .______    _______      ______  __       __    __  .______   
|   \/   |  /  __  \   /  __  \  |  \ |  |        /   \     |   _  \  |   ____|    /      ||  |     |  |  |  | |   _  \  
|  \  /  | |  |  |  | |  |  |  | |   \|  |       /  ^  \    |  |_)  | |  |__      |  ,----'|  |     |  |  |  | |  |_)  | 
|  |\/|  | |  |  |  | |  |  |  | |  . `  |      /  /_\  \   |   ___/  |   __|     |  |     |  |     |  |  |  | |   _  <  
|  |  |  | |  `--'  | |  `--'  | |  |\   |     /  _____  \  |  |      |  |____    |  `----.|  `----.|  `--'  | |  |_)  | 
|__|  |__|  \______/   \______/  |__| \__|    /__/     \__\ | _|      |_______|    \______||_______| \______/  |______/                                                                                                                        
*/

/**
 * @title MoonApeClub contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MoonApeClub is
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant WHITELIST_SUPPLY = 3000;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_ADDRESS = 10;

    // State variables
    // ------------------------------------------------------------------------
    string private _baseTokenURI;
    bool public isWhitelistSaleActive = false;
    bool public isPublicSaleActive = false;
    uint256 public price = 0.05 ether;

    // Sale mappings
    // ------------------------------------------------------------------------
    mapping(address => uint256) public minted;

    // Merkle Root Hash
    // ------------------------------------------------------------------------
    bytes32 private _merkleRoot;

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyWhitelistSaleActive() {
        require(isWhitelistSaleActive, "Whitelist sale is not active");
        _;
    }

    modifier onlyPublicSaleActive() {
        require(isPublicSaleActive, "Public sale is not active");
        _;
    }

    modifier onlyEOA() {
        require(
            tx.origin == msg.sender,
            "Contract caller must be externally owned account"
        );
        _;
    }

    modifier mintCompliance(uint256 numberOfTokens) {
        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_PER_TX,
            "Exceeds max per transaction"
        );
        require(
            minted[_msgSender()] + numberOfTokens <= MAX_PER_ADDRESS,
            "Exceeds per address supply"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        _;
    }

    // Constructor
    // ------------------------------------------------------------------------
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    // URI functions
    // ------------------------------------------------------------------------
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Operational functions
    // ------------------------------------------------------------------------
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // Merkle root functions
    // ------------------------------------------------------------------------
    function setMerkleRoot(bytes32 rootHash) external onlyOwner {
        _merkleRoot = rootHash;
    }

    function verifyProof(bytes32[] memory _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    // Sale switch functions
    // ------------------------------------------------------------------------
    function flipWhitelistSale() public onlyOwner {
        isWhitelistSaleActive = !isWhitelistSaleActive;
    }

    function flipPublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    // Mint functions
    // ------------------------------------------------------------------------
    function whitelistMint(uint256 numberOfTokens, bytes32[] calldata proof)
        public
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyWhitelistSaleActive
        mintCompliance(numberOfTokens)
    {
        require(
            totalSupply() + numberOfTokens <= WHITELIST_SUPPLY,
            "Max whitelist supply exceeded"
        );
        require(verifyProof(proof), "Not in the whitelist");

        minted[_msgSender()] += numberOfTokens;
        _mint(_msgSender(), numberOfTokens);
    }

    function publicMint(uint256 numberOfTokens)
        public
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyPublicSaleActive
        mintCompliance(numberOfTokens)
    {
        require(
            price.mul(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );

        minted[_msgSender()] += numberOfTokens;
        _mint(_msgSender(), numberOfTokens);
    }
}