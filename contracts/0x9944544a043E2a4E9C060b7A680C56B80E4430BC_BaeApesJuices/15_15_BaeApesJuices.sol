// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract BaeApesJuices is ERC1155, Ownable, PaymentSplitter {

    using Strings for uint256;

    struct Token {
        uint16 maxSupply;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool supplyLock;
        uint16 totalSupply;
    }

    mapping(uint256 => Token) public tokens;
    mapping(address => uint16) public hasClaimed;
    mapping(uint256 => bool) public claimableType;
    string public name;
    string public symbol;
    string private baseURI;
    bytes32 public claimMerkleRoot;
    address public burnerContract;
    bool public preSaleIsActive;
    bool public saleIsActive;
    bool public claimIsActive;
    uint256 public maxPerTransaction;

    modifier onlyBurner() {
        require(msg.sender == burnerContract, "Not authorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner
    ) ERC1155(_uri) PaymentSplitter(_payees, _shares) {
        name = _name;
        symbol = _symbol;
        baseURI = _uri;
        transferOwnership(_owner);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function addClaimableType(uint256 _id) external onlyOwner {
        claimableType[_id] = true;
    }

    function removeClaimableType(uint256 _id) external onlyOwner {
        delete claimableType[_id];
    }

    function price(uint256 _id) internal view returns (uint256) {
        return preSaleIsActive ? tokens[_id].preSalePrice : tokens[_id].pubSalePrice;
    }

    function setBurnerAddress(address _address) external onlyOwner {
        burnerContract = _address;
    }

    function burnForAddress(uint256[] memory _ids, uint256[] memory _quantities, address _address) external onlyBurner {
        _burnBatch(_address, _ids, _quantities);
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    function lockSupply(uint256 _id) public onlyOwner {
        tokens[_id].supplyLock = true;
    }

    function setClaimRoot(bytes32 _root) public onlyOwner {
        claimMerkleRoot = _root;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) public onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function updateSaleState(
        bool _preSaleIsActive, 
        bool _saleIsActive,
        bool _claimIsActive
    ) public onlyOwner {
        if (_claimIsActive) require(claimMerkleRoot != "", "Root undefined");
        preSaleIsActive = _preSaleIsActive;
        saleIsActive = _saleIsActive;
        claimIsActive = _claimIsActive;
    }

    function updateType(
        uint256 _id,
        uint16 _maxSupply,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(_maxSupply >= tokens[_id].totalSupply, "Invalid supply");
        require(tokens[_id].maxSupply != 0, "Invalid token");
        if (tokens[_id].supplyLock) {
            require(_maxSupply == tokens[_id].maxSupply, "Supply is locked");
        }
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
    }

    function createType(
        uint256 _id,
        uint16 _maxSupply,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(tokens[_id].maxSupply == 0, "Token exists");
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
    }

    function mint(
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) public payable {
        require(_ids.length == _quantities.length, "Invalid parameters");
        require(saleIsActive, "Sale inactive");
        uint256 _price = 0;
        uint256 _quantity = 0;
        for (uint16 i = 0; i < _ids.length; i++) {
            require(tokens[_ids[i]].maxSupply != 0, "Invalid token");
            require(tokens[_ids[i]].totalSupply + _quantities[i] <= tokens[_ids[i]].maxSupply, "Insufficient supply");
            _price += price(_ids[i]) * _quantities[i];
            _quantity += _quantities[i];
        }
        require(_price <= msg.value, "ETH incorrect");
        require(_quantity <= maxPerTransaction, "Invalid quantity");
        for (uint16 i = 0; i < _ids.length; i++) {
            tokens[_ids[i]].totalSupply = tokens[_ids[i]].totalSupply + uint16(_quantities[i]);
        }
        _mintBatch(msg.sender, _ids, _quantities, "");
    }

    function claimFree(uint256[] memory _ids, uint16 _maxMint, uint256[] memory _quantities, bytes32[] memory _proof) public {
        require(_ids.length == _quantities.length, "Invalid parameters");
        require(claimIsActive, "Claim inactive");
        uint16 _hasClaimed = hasClaimed[msg.sender];
        uint256 _quantity = 0;
        for (uint16 i = 0; i < _ids.length; i++) {
            require(claimableType[_ids[i]], "Not claimable.");
            require(tokens[_ids[i]].maxSupply != 0, "Invalid token");
            require(tokens[_ids[i]].totalSupply + _quantities[i] <= tokens[_ids[i]].maxSupply, "Insufficient supply");
            _quantity += _quantities[i];
        }
        bytes32 leaf = keccak256(abi.encode(msg.sender, _maxMint));
        require(MerkleProof.verify(_proof, claimMerkleRoot, leaf), "Not whitelisted");
        uint16 _claimable = _maxMint - _hasClaimed;
        require(_quantity <= _claimable, "Invalid quantity");
        for (uint16 i = 0; i < _ids.length; i++) {
            tokens[_ids[i]].totalSupply = tokens[_ids[i]].totalSupply + uint16(_quantities[i]);
        }
        hasClaimed[msg.sender] = _hasClaimed + uint16(_quantity);
        _mintBatch(msg.sender, _ids, _quantities, "");
    }

    function reserve(uint256 _id, address _address, uint16 _quantity) public onlyOwner {
        uint16 _currentSupply = tokens[_id].totalSupply;
        require(_currentSupply + _quantity <= tokens[_id].maxSupply, "Insufficient supply");
        tokens[_id].totalSupply = _currentSupply + _quantity;
        _mint(_address, _id, _quantity, "");
    }
}