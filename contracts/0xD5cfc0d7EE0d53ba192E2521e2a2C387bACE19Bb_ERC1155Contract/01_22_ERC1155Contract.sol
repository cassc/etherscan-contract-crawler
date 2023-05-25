// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";
import "refer2earn/Referable.sol";

contract ERC1155Contract is ERC1155, Ownable, PaymentSplitter, ReentrancyGuard, DefaultOperatorFilterer, Referable {

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
        uint16 totalSupply;
        bool transferrable;
    }

    mapping(uint256 => Token) public tokens;
    mapping (uint256 => mapping(address => uint16)) public hasMinted;
    mapping (uint256 => mapping(address => uint16)) public hasClaimed;
    mapping (uint256 => bytes32) public saleMerkleRoot;
    mapping (uint256 => bytes32) public claimMerkleRoot;

    string public name;
    string public symbol;
    string private baseURI;
    address burnerContract;
    address crossmintManager;

    modifier onlyCrossmint() {
        require(crossmintManager == msg.sender, "Unauthorized");
        _;
    }

    modifier onlyBurner() {
        require(msg.sender == burnerContract, "Unauthorized");
        _;
    }

    constructor(
        uint16 _id,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        address _r2eAddress,
        address _crossmintAddress,
        Token memory _type
    ) ERC1155(_uri)
      Referable(_r2eAddress)
      PaymentSplitter(_payees, _shares) {
        name = _name;
        symbol = _symbol;
        baseURI = _uri;
        tokens[_id]= _type;
        crossmintManager = _crossmintAddress;
        transferOwnership(_owner);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        require(tokens[tokenId].transferrable, "Failed");
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        for (uint256 i; i < ids.length; i++) require(tokens[ids[i]].transferrable, "Failed");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function setBurnerAddress(address _address) external onlyOwner {
        burnerContract = _address;
    }

    function burnForAddress(uint256 _id, uint256 _quantity, address _address) external onlyBurner {
        _burn(_address, _id, _quantity);
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setSaleRoot(uint256 _id, bytes32 _root) external onlyOwner {
        saleMerkleRoot[_id] = _root;
    }

    function setClaimRoot(uint256 _id, bytes32 _root) external onlyOwner {
        claimMerkleRoot[_id] = _root;
    }

    function updateSaleState(
        uint256 _id, 
        bool _preSaleIsActive,
        bool _pubSaleIsActive,
        bool _claimIsActive
    ) external onlyOwner {
        if (_claimIsActive) require(claimMerkleRoot[_id] != "", "Bad root");
        tokens[_id].preSaleIsActive = _preSaleIsActive;
        tokens[_id].pubSaleIsActive = _pubSaleIsActive;
        tokens[_id].claimIsActive = _claimIsActive;

    }

    function setType(
        uint256 _id,
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice,
        bool _supplyLock
    ) external onlyOwner {
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].maxPerWallet = _maxPerWallet;
        tokens[_id].maxPerTransaction = _maxPerTransaction;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
        tokens[_id].supplyLock = _supplyLock;
    }

    function _mintTo(
        uint256 _id,
        address _address,
        uint256 _quantity,
        bytes32[] memory _proof,
        address payable _referrer,
        uint256 _value
    ) internal {
        bool _isEligiblePreSale;
        bool _isEligiblePubSale;
        bool hasSupply = tokens[_id].totalSupply + _quantity <= tokens[_id].maxSupply;
        if(tokens[_id].preSaleIsActive) {
            _isEligiblePreSale = hasSupply && ((hasMinted[_id][_address] + _quantity) <= tokens[_id].maxPerWallet);
            if (saleMerkleRoot[_id] != "") {
                _isEligiblePreSale = _isEligiblePreSale && MerkleProof.verify(_proof, saleMerkleRoot[_id], keccak256(abi.encodePacked(_address)));
            }
        }
        if (tokens[_id].pubSaleIsActive) {
            _isEligiblePubSale = hasSupply && (_quantity <= tokens[_id].maxPerTransaction);
        }
        require(_isEligiblePreSale || _isEligiblePubSale, "Ineligible");
        if (_isEligiblePreSale) {
            require(tokens[_id].preSalePrice * _quantity <= _value, "ETH incorrect");
            hasMinted[_id][_address] += uint16(_quantity);
        }
        if (!_isEligiblePreSale && _isEligiblePubSale) {
            require(tokens[_id].pubSalePrice * _quantity <= _value, "ETH incorrect");
        }
        tokens[_id].totalSupply += uint16(_quantity);
        _mint(_address, _id, _quantity, "");
        Referable.payReferral(_address, _referrer, _quantity, _value);
    }

    function mint(
        uint256 _id,
        uint256 _quantity,
        bytes32[] memory _proof,
        address payable _referrer
    ) external payable nonReentrant {
        _mintTo(_id, msg.sender, _quantity, _proof, _referrer, msg.value);
    }

    function crossmint(address _address, uint256 _quantity, uint256 _id, bytes32[] memory _proof, address payable _referrer) external payable nonReentrant onlyCrossmint {
        _mintTo(_id, _address, _quantity, _proof, _referrer, msg.value);
    }

    function claim(uint256 _id, uint16 _maxMint, uint16 _quantity, bytes32[] memory _proof) external {
        require(tokens[_id].claimIsActive, "Claim off");
        uint16 _hasClaimed = hasClaimed[_id][msg.sender];
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "No supply");
        require(MerkleProof.verify(_proof, claimMerkleRoot[_id], keccak256(abi.encode(msg.sender, _maxMint))), "Not allowed");
        require(_quantity <= _maxMint - _hasClaimed, "Bad quantity");
        tokens[_id].totalSupply = _currentSupply + _quantity;
        hasClaimed[_id][msg.sender] = _hasClaimed + _quantity;
        _mint(msg.sender, _id, _quantity, "");
    }

    function reserve(uint256 _id, address _address, uint16 _quantity) external onlyOwner nonReentrant {
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "No supply");
        tokens[_id].totalSupply = _currentSupply + _quantity;
        _mint(_address, _id, _quantity, "");
    }
}