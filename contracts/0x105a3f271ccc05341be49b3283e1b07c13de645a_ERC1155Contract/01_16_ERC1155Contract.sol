// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Contract is ERC1155, Ownable, PaymentSplitter, ReentrancyGuard {

    using Strings for uint256;

    struct Token {
        uint16 maxSupply;
        uint16 maxPerWallet;
        uint16 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool saleIsActive;
        bool claimIsActive;
        bool supplyLock;
        uint16 totalSupply;
    }

    mapping(uint256 => Token) public tokens;
    mapping(address => bool) public fiatAllowlist;
    mapping (uint256 => mapping(address => uint16)) public hasMinted;
    mapping (uint256 => mapping(address => uint16)) public hasClaimed;
    string public name;
    string public symbol;
    string private baseURI;
    bytes32 public saleMerkleRoot;
    bytes32 public claimMerkleRoot;
    address public burnerContract;

    modifier onlyFiatMinter() {
        require(fiatAllowlist[msg.sender], "Not authorized");
        _;
    }

    modifier onlyBurner() {
        require(msg.sender == burnerContract, "Not authorized");
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
        Token memory _type
    ) ERC1155(_uri) PaymentSplitter(_payees, _shares) {
        name = _name;
        symbol = _symbol;
        baseURI = _uri;
        tokens[_id]= _type;
        transferOwnership(_owner);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function getClaimIneligibilityReason(address _address, uint256 _quantity, uint256 _id) public view returns (string memory) {
        if (uint256(tokens[_id].totalSupply) + _quantity > uint256(tokens[_id].maxSupply)) return "NOT_ENOUGH_SUPPLY";
        if (tokens[_id].preSaleIsActive || !tokens[_id].saleIsActive) return "NOT_LIVE";
        if (!tokens[_id].preSaleIsActive && tokens[_id].saleIsActive) return "";
    }

    function unclaimedSupply(uint256 _id) public view returns (uint256) {
        return tokens[_id].maxSupply - tokens[_id].totalSupply;
    }

    function price(uint256 _id) public view returns (uint256) {
        return tokens[_id].preSaleIsActive ? tokens[_id].preSalePrice : tokens[_id].pubSalePrice;
    }

    function addFiatMinter(address _address) public onlyOwner {
        fiatAllowlist[_address] = true;
    }

    function removeFiatMinter(address _address) public onlyOwner {
        delete fiatAllowlist[_address];
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
    function lockSupply(uint256 _id) public onlyOwner {
        tokens[_id].supplyLock = true;
    }

    function setSaleRoot(bytes32 _root) public onlyOwner {
        saleMerkleRoot = _root;
    }

    function setClaimRoot(bytes32 _root) public onlyOwner {
        claimMerkleRoot = _root;
    }

    function updateSaleState(
        uint256 _id, 
        bool _preSaleIsActive, 
        bool _saleIsActive,
        bool _claimIsActive
    ) public onlyOwner {
        if (_preSaleIsActive) require(saleMerkleRoot != "", "Root undefined");
        if (_claimIsActive) require(claimMerkleRoot != "", "Root undefined");
        tokens[_id].preSaleIsActive = _preSaleIsActive;
        tokens[_id].saleIsActive = _saleIsActive;
        tokens[_id].claimIsActive = _claimIsActive;
    }

    function updateType(
        uint256 _id,
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(_maxSupply >= tokens[_id].totalSupply, "Invalid supply");
        require(tokens[_id].maxSupply != 0, "Invalid token");
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].maxPerWallet = _maxPerWallet;
        tokens[_id].maxPerTransaction = _maxPerTransaction;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
    }

    function createType(
        uint256 _id,
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(tokens[_id].maxSupply == 0, "Token exists");
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].maxPerWallet = _maxPerWallet;
        tokens[_id].maxPerTransaction = _maxPerTransaction;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
    }

    function mint(
        uint256 _id,
        uint16 _quantity,
        bytes32[] memory _proof
    ) public payable nonReentrant {
        uint16 _maxPerWallet = tokens[_id].maxPerWallet;
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(price(_id) * _quantity <= msg.value, "ETH incorrect");
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        require(tokens[_id].saleIsActive, "Sale inactive");
        if(tokens[_id].preSaleIsActive) {
            uint16 mintedAmount = hasMinted[_id][msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Invalid quantity");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_proof, saleMerkleRoot, leaf), "Not whitelisted");
            hasMinted[_id][msg.sender] = mintedAmount;
        } else {
            require(_quantity <= tokens[_id].maxPerTransaction, "Invalid quantity");
        }   
        tokens[_id].totalSupply = _currentSupply + _quantity;
        _mint(msg.sender, _id, _quantity, "");
    }

    function claimTo(address _address, uint256 _quantity, uint256 _id) public payable nonReentrant onlyFiatMinter {
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(tokens[_id].saleIsActive, "Sale inactive");
        require(uint256(_currentSupply) + _quantity <= uint256(tokens[_id].maxSupply), "Insufficient supply");
        require(price(_id) * _quantity <= msg.value, "ETH incorrect");
        tokens[_id].totalSupply = _currentSupply + uint16(_quantity);
        _mint(_address, _id, _quantity, "");
    }

    function claimFree(uint256 _id, uint16 _maxMint, uint16 _quantity, bytes32[] memory _proof) public {
        require(tokens[_id].claimIsActive, "Claim inactive");
        uint16 _hasClaimed = hasClaimed[_id][msg.sender];
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        bytes32 leaf = keccak256(abi.encode(msg.sender, _maxMint));
        require(MerkleProof.verify(_proof, claimMerkleRoot, leaf), "Not whitelisted");
        uint16 _claimable = _maxMint - _hasClaimed;
        require(_quantity <= _claimable, "Invalid quantity");
        tokens[_id].totalSupply = _currentSupply + _quantity;
        hasClaimed[_id][msg.sender] = _hasClaimed + _quantity;
        _mint(msg.sender, _id, _quantity, "");
    }

    function reserve(uint256 _id, address _address, uint16 _quantity) public onlyOwner nonReentrant {
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        tokens[_id].totalSupply = _currentSupply + _quantity;
        _mint(_address, _id, _quantity, "");
    }
}