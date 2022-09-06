// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheLittleRascals is ERC721A, Ownable {
    using Strings for uint256;

    // [--TLR SUPPLY--]
    uint256 public constant MAX_SUPPLY = 3333; 

    // [--TLR PRICE--]
    uint256 public publicSalePrice; 
    uint256 public preSalePrice;
    uint256 public teamMintPrice = 0.1 ether;
    uint256 public communitySalePrice; 

    // [--TLR MAX MINT--]
    uint256 public maxCommunityMint = 1;
    uint256 public maxPublicSaleMint = 5;

    // [--TLR MINT STATUS--]
    bool public isPreSaleActive;
    bool public isCommunitySaleActive;
    bool public isPublicSaleActive;

    // [--TLR METADATA--]
    bool public isRevealed;
    string private _baseTokenURI;

    // [--TLR MERKLEROOT--]
    bytes32 public preSaleMerkleRoot;
    bytes32 public communitySaleMerkleRoot;

    // [--MINTED--]
    mapping(address => uint256) public preSaleMinted;
    mapping(address => bool) public communitySaleMinted;
    mapping(address => uint256) public publicSaleMinted;



    // [--CONSTRUCTOR--]   
    constructor() ERC721A("TheLittleRascals", "TLR") {}

    /**
     * @notice must be an EOA
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // [--MINT--]
    // PRESALE MINT
    function preSaleMint(uint256 _quantity, uint256 _maxAmount,  bytes32[] calldata _proof) external payable callerIsUser {
        require(isPreSaleActive, "PRESALE NOT ACTIVE");
        require(msg.value == preSalePrice * _quantity, "NEED TO SEND CORRECT ETH AMOUNT");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(preSaleMinted[msg.sender] + _quantity <= _maxAmount, "EXCEEDS MAX CLAIM"); 
        bytes32 sender = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        bool isValidProof = MerkleProof.verify(_proof, preSaleMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        preSaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // SALE MINT
    function communitySaleMint(uint256 _maxAmount, bytes32[] calldata _proof) external payable callerIsUser {
        require(isCommunitySaleActive, "COMMUNITY SALE NOT ACTIVE");
        require(msg.value == communitySalePrice, "NEED TO SEND CORRECT ETH AMOUNT");
        require(totalSupply() + maxCommunityMint <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(!communitySaleMinted[msg.sender], "EXCEEDS MAX CLAIM"); 
        bytes32 sender = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        bool isValidProof = MerkleProof.verify(_proof, communitySaleMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        communitySaleMinted[msg.sender] = true;
        _safeMint(msg.sender, maxCommunityMint);
    }
    
    // PUBLIC MINT
    function publicSaleMint(uint256 _quantity) external payable callerIsUser {
        require(isPublicSaleActive, "PUBLIC SALE IS NOT ACTIVE");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(publicSaleMinted[msg.sender] + _quantity <= maxPublicSaleMint, "EXCEEDS MAX MINTS PER ADDRESS"); 
        require(msg.value == publicSalePrice * _quantity, "NEED TO SEND CORRECT ETH AMOUNT");

        publicSaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    // TEAM MINT
    function teamMint(uint256 _quantity) external payable onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(msg.value == teamMintPrice, "NEED TO SEND CORRECT ETH AMOUNT");
        // [--FOUNDER MINT--]     
        _safeMint(msg.sender, _quantity);
    }

    // [-- SALE CONFIG--]
    /**
     * @notice activating or deactivating presale status
     */
    function setPreSaleStatus(bool _status) external onlyOwner {
        isPreSaleActive = _status;
    }
    
    /**
     * @notice activating or deactivating community sale status
     */
    function setCommunitySaleStatus(bool _status) external onlyOwner {
        isCommunitySaleActive = _status;
    }

    /**
     * @notice activating or deactivating public sale
     */
    function setPublicSaleStatus(bool _status) external onlyOwner {
        isPublicSaleActive = _status;
    }

    // [--PRICE SETTING--]
    /**
     * @notice set presale price
     */
    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    /**
     * @notice set whitelist price
     */
    function setCommunitySalePrice(uint256 _price) external onlyOwner {
        communitySalePrice = _price;
    }

    /**
     * @notice set public sale price
     */
    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    // [--MERKLEROOT SETTING--]
    /**
     * @notice set presale merkleroot
     */
    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        preSaleMerkleRoot = _merkleRoot;
    }

    /**
     * @notice set community sale merkleroot
     */
    function setCommunitySaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = _merkleRoot;
    }

    
    // [--METADATA URI SETTING--]
    /**
     * @notice tokenURI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        if (!isRevealed) {
            return _baseTokenURI;
        } else{
            return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
        }
    }

    /**
     * @notice set base URI
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }   

    /**
     * @notice set IsRevealed to true or false
     */
    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }   

    /** 
    *   @notice set startTokenId to 1
    */
    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    // [--WITHDRAW--]

    /**
     * @notice withdraw funds to 
     */

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
  }
}