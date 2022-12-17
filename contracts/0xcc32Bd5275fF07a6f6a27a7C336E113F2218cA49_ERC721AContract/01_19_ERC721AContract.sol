// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";
import "./IMintPass.sol";
import "refer2earn/Referable.sol";

contract ERC721AContract is ERC721A, Ownable, PaymentSplitter, DefaultOperatorFilterer, ReentrancyGuard, Referable {

    using Strings for uint256;

    struct Token {
        uint16 maxSupply;
        uint16 maxPerWallet;
        uint16 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool pubSaleIsActive;
        bool claimIsActive;
        bool supplyLock;
        uint8 preSalePhase;
        bool transferrable;
    }

    mapping(address => uint16) public hasMinted;
    mapping(address => uint16) public hasClaimed;
    bytes32 public saleMerkleRoot;
    bytes32 public claimMerkleRoot;
    Token public token;
    string private baseURI;
    MintPass public mintpass;
    string public provenance;
    address crossmintManager;

    modifier onlyCrossmint() {
        require(crossmintManager == msg.sender, "Unauthorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        address _r2eAddress,
        address _crossmintAddress,
        string memory _provenance,
        Token memory _token
    ) ERC721A(_name, _symbol)
      Referable(_r2eAddress)
      PaymentSplitter(_payees, _shares) {
        provenance = _provenance;
        baseURI = _uri;
        token = _token;
        crossmintManager = _crossmintAddress;
        transferOwnership(_owner);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        require(token.transferrable, "Failed");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        require(token.transferrable, "Failed");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        require(token.transferrable, "Failed");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() override internal pure returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function setMintPass(address _address) external onlyOwner {
        mintpass = MintPass(_address);
    }

    function updateConfig(
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice,
        bool _supplyLock
    ) external onlyOwner {
        require(_maxSupply >= totalSupply(), "Invalid supply");
        if (token.supplyLock) {
            require(_maxSupply == token.maxSupply, "Locked");
        }
        token.maxSupply = _maxSupply;
        token.maxPerWallet = _maxPerWallet;
        token.maxPerTransaction = _maxPerTransaction;
        token.preSalePrice = _preSalePrice;
        token.pubSalePrice = _pubSalePrice;
        token.supplyLock = _supplyLock;
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setSaleRoot(bytes32 _root) external onlyOwner {
        saleMerkleRoot = _root;
    }

    function setClaimRoot(bytes32 _root) external onlyOwner {
        claimMerkleRoot = _root;
    }

    function updateSaleState(
        bool _preSaleIsActive,
        bool _pubSaleIsActive,
        uint8 _preSalePhase,
        bool _claimIsActive
    ) external onlyOwner {
        require(_preSalePhase == 0 || _preSalePhase == 1 || _preSalePhase == 2, "Bad phase");
        if (_preSaleIsActive && _preSalePhase == 1) require(address(mintpass) != address(0), "MintPass undefined");
        if (_claimIsActive) require(claimMerkleRoot != "", "Bad root");
        token.preSaleIsActive = _preSaleIsActive;
        token.pubSaleIsActive = _pubSaleIsActive;
        token.preSalePhase = _preSalePhase;
        token.claimIsActive = _claimIsActive;
    }

    function _mintTo(
        address _address,
        uint256 _quantity,
        bytes32[] memory _proof,
        address payable _referrer,
        uint256 _value
    ) internal {
        bool hasSupply = uint16(totalSupply()) + _quantity <= token.maxSupply;
        bool _isEligiblePreSale = hasSupply;
        bool _isEligiblePubSale = hasSupply;
        if(token.preSaleIsActive) {
            if (token.preSalePhase == 1) {
                _isEligiblePreSale = _isEligiblePreSale && mintpass.balanceOf(_address, 1) >= _quantity;
            }
            if (token.preSalePhase == 2) {
                if (saleMerkleRoot != "") {
                    _isEligiblePreSale = _isEligiblePreSale && MerkleProof.verify(_proof, saleMerkleRoot, keccak256(abi.encodePacked(_address)));
                }
                _isEligiblePreSale = _isEligiblePreSale && (hasMinted[_address] + _quantity) <= token.maxPerWallet;
            }
        }
        if (token.pubSaleIsActive) {
            _isEligiblePubSale = _isEligiblePubSale && _quantity <= token.maxPerTransaction;
        }
        require(_isEligiblePreSale || _isEligiblePubSale, "Ineligible");
        if (_isEligiblePreSale) {
            require(token.preSalePrice * _quantity <= _value, "ETH incorrect");
            if (token.preSalePhase == 1) {
                mintpass.burnForAddress(1, _quantity, _address);
            }
            if (token.preSalePhase == 2) {
                hasMinted[_address] += uint16(_quantity);
            }
        }
        if (!_isEligiblePreSale && _isEligiblePubSale) {
            require(token.pubSalePrice * _quantity <= _value, "ETH incorrect");
        }
        _safeMint(_address, _quantity);
        Referable.payReferral(_address, _referrer, _quantity, _value);
    }

    function mint(
        uint256 _quantity,
        bytes32[] memory _proof,
        address payable _referrer
    ) external payable nonReentrant {
        _mintTo(msg.sender, _quantity, _proof, _referrer, msg.value);
    }

    function crossmint(address _address, uint256 _quantity, bytes32[] memory _proof, address payable _referrer) external payable nonReentrant onlyCrossmint {
        _mintTo(_address, _quantity, _proof, _referrer, msg.value);
    }

    function claim(uint16 _maxMint, uint16 _quantity, bytes32[] memory _proof) external {
        require(token.claimIsActive, "Claim off");
        require(uint16(totalSupply()) + _quantity <= token.maxSupply, "No supply");
        uint16 _hasClaimed = hasClaimed[msg.sender];
        require(MerkleProof.verify(_proof, claimMerkleRoot, keccak256(abi.encode(msg.sender, _maxMint))), "Not allowed");
        uint16 _claimable = _maxMint - _hasClaimed;
        require(_quantity <= _claimable, "Bad quantity");
        hasClaimed[msg.sender] = _hasClaimed + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserve(address _address, uint16 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= token.maxSupply, "No supply");
        _safeMint(_address, _quantity);
    }
}