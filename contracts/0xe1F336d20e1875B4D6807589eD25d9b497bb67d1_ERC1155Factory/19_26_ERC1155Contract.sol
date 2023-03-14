// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "refer2earn/Referable.sol";
import "./opensea/DefaultOperatorFilterer.sol";
import "./IERC2981.sol";
import "./IDelegationRegistry.sol";

contract ERC1155Contract is ERC1155, Ownable, PaymentSplitter, ReentrancyGuard, DefaultOperatorFilterer, Referable, IERC2981 {

    using Strings for uint256;
    IDelegationRegistry immutable dc;

    struct RoyaltyInfo {
        address recipient;
        uint24 basisPoints;
    }

    struct Token {
        uint16 maxSupply;
        bool pubPerWallet;
        uint16 pubMaxMint;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool pubSaleIsActive;
        bool claimIsActive;
        bool supplyLock;
        bool refer2earn;
        uint16 totalSupply;
        bool soulbound;
    }

    struct Eligible {
        bool claim;
        bool preSale;
        bool pubSale;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;
    mapping(uint256 => Token) public tokens;
    mapping (uint256 => mapping(address => uint16)) public hasMinted;
    mapping (uint256 => mapping(address => uint16)) public hasClaimed;
    mapping(address => bool) public fiatMinters;

    string public name;
    string public symbol;
    string private baseURI;
    address private burnerContract;
    bytes32 private saleMerkleRoot;
    bytes32 private claimMerkleRoot;

    constructor(
        uint16 _id,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        address[] memory _interfaces, // 0 = refer2earn, 1 = delegate.cash, 2 = crossmint
        Token memory _type,
        RoyaltyInfo memory _royalties
    ) ERC1155(_uri)
      Referable(_interfaces[0])
      PaymentSplitter(_payees, _shares) {
        name = _name;
        symbol = _symbol;
        baseURI = _uri;
        tokens[_id] = _type;
        royalties[_id] = _royalties;
        dc = IDelegationRegistry(_interfaces[1]);
        fiatMinters[_interfaces[2]] = true;
        transferOwnership(_owner);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        require(!tokens[tokenId].soulbound, "Failed");
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        for (uint256 i; i < ids.length; i++) require(!tokens[ids[i]].soulbound, "Failed");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function setFiatMinter(address _address, bool _allowed) external onlyOwner {
        if (_allowed) {
            fiatMinters[_address] = true;
        } else {
            delete fiatMinters[_address];
        }
    }

    function setBurnerAddress(address _address) external onlyOwner {
        burnerContract = _address;
    }

    function burnForAddress(uint256 _id, uint256 _quantity, address _address) external {
        require(msg.sender == burnerContract, "Unauthorized");
        tokens[_id].totalSupply -= uint16(_quantity);
        _burn(_address, _id, _quantity);
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setSaleRoot(bytes32 _root) external onlyOwner {
        saleMerkleRoot = _root;
    }

    function setClaimRoot(bytes32 _root) external onlyOwner {
        claimMerkleRoot = _root;
    }

    function updateSaleState(
        uint256 _id, 
        bool _preSaleIsActive,
        bool _pubSaleIsActive,
        bool _claimIsActive
    ) external onlyOwner {
        if (_claimIsActive) require(claimMerkleRoot != "", "Bad root");
        if (_preSaleIsActive) require(saleMerkleRoot != "", "Bad root");
        tokens[_id].preSaleIsActive = _preSaleIsActive;
        tokens[_id].pubSaleIsActive = _pubSaleIsActive;
        tokens[_id].claimIsActive = _claimIsActive;
    }

    function setType(
        uint256 _id,
        uint16 _maxSupply,
        bool _pubPerWallet,
        uint16 _pubMaxMint,
        uint72 _preSalePrice,
        uint72 _pubSalePrice,
        bool _supplyLock,
        bool _refer2earn,
        bool _soulbound
    ) external onlyOwner {
        require(_soulbound == tokens[_id].soulbound || tokens[_id].totalSupply == 0, "Locked");
        if (tokens[_id].supplyLock) require(_maxSupply == tokens[_id].maxSupply, "Locked");
        if (tokens[_id].totalSupply == 0) tokens[_id].soulbound = _soulbound;
        tokens[_id].maxSupply = _maxSupply;
        tokens[_id].pubPerWallet = _pubPerWallet;
        tokens[_id].pubMaxMint = _pubMaxMint;
        tokens[_id].preSalePrice = _preSalePrice;
        tokens[_id].pubSalePrice = _pubSalePrice;
        tokens[_id].supplyLock = _supplyLock;
        tokens[_id].refer2earn = _refer2earn;
    }

    function isEligible(
        address _address,
        uint256 _id,
        uint16 _quantity,
        uint16 _maxMint,
        bytes32[] memory _proof,
        uint256 _value
    ) internal returns (Eligible memory) {
        Eligible memory _isEligible;
        Token memory _token = tokens[_id];
        uint16 _hasMinted = hasMinted[_id][_address];
        uint16 _hasClaimed = hasClaimed[_id][_address];
        if(_token.claimIsActive && (_quantity <= (_maxMint - _hasClaimed)) && _value == 0) {
            bytes32 _leaf = keccak256(abi.encode(_address, _id, _maxMint));
            _isEligible.claim = MerkleProof.verify(_proof, claimMerkleRoot, _leaf);
            if (_isEligible.claim) hasClaimed[_id][_address] += _quantity;
        }
        if(!_isEligible.claim && _token.preSaleIsActive && (_quantity <= _maxMint - _hasMinted) && (_value == _token.preSalePrice * _quantity)) {
            bytes32 _leaf = keccak256(abi.encode(_address, _id, _maxMint));
            _isEligible.preSale = MerkleProof.verify(_proof, saleMerkleRoot, _leaf);
            if (_isEligible.preSale) hasMinted[_id][_address] += _quantity;
        }
        if (!_isEligible.claim && !_isEligible.preSale && _token.pubSaleIsActive && (_value == _token.pubSalePrice * _quantity)) {
            if (_token.pubPerWallet) {
                _isEligible.pubSale = (_quantity <= (_token.pubMaxMint - _hasMinted));
            } else {
                _isEligible.pubSale = (_quantity <= _token.pubMaxMint);
            }
            if (_isEligible.pubSale && (_token.pubPerWallet)) hasMinted[_id][_address] += _quantity;
        }
        return _isEligible;
    }

    function mint(
        address _address,
        uint256 _id,
        uint256 _quantity,
        uint256 _maxMint,
        bytes32[] memory _proof,
        address payable _referrer
    ) external payable nonReentrant {
        require(_address != address(0), "Bad address");
        if (_address != msg.sender) require((fiatMinters[msg.sender] || dc.checkDelegateForContract(msg.sender, _address, address(this))), "Unauthorized");
        require(tokens[_id].totalSupply + _quantity <= tokens[_id].maxSupply, "No supply");
        (Eligible memory _isEligible) = isEligible(_address, _id, uint16(_quantity), uint16(_maxMint), _proof, msg.value);
        require(_isEligible.claim || _isEligible.preSale || _isEligible.pubSale, "Ineligible");
        tokens[_id].totalSupply += uint16(_quantity);
        _mint(_address, _id, _quantity, "");
        if (tokens[_id].refer2earn) Referable.payReferral(_address, _referrer, _quantity, msg.value);
    }

    function setRoyalties(uint256 _id, address recipient, uint256 _basisPoints) external onlyOwner {
        royalties[_id] = RoyaltyInfo(recipient, uint24(_basisPoints));
    }

    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royalties[_id].recipient, (_salePrice * royalties[_id].basisPoints) / 10000);
    }

    function airdrop(address[] memory _addresses, uint16[] memory _ids, uint16[] memory _quantities) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            uint16 _id = _ids[i];
            require(tokens[_id].totalSupply + _quantities[i] <= tokens[_id].maxSupply, "No supply");
            _mint(_addresses[i], _id, _quantities[i], "");
            tokens[_id].totalSupply += uint16(_quantities[i]);
        }
    }
}