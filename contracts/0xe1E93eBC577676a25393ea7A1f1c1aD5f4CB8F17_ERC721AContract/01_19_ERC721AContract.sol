// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@paperxyz/contracts/keyManager/IPaperKeyManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";
import "./IMintPass.sol";

contract ERC721AContract is ERC721A, Ownable, PaymentSplitter, DefaultOperatorFilterer, ReentrancyGuard {

    using Strings for uint256;

    event Referral(address indexed _referrer, uint256 _quantity, uint256 _commission);

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
    }

    mapping(address => uint8) public referrers;
    mapping(address => uint16) public hasMinted;
    mapping(address => uint16) public hasClaimed;
    bytes32 public saleMerkleRoot;
    bytes32 public claimMerkleRoot;
    Token public token;
    string private baseURI;
    MintPass public mintpass;
    string public provenance;
    uint8 public referralFee;
    IPaperKeyManager paperKeyManager;
    address crossmintManager;

    modifier onlyPaper(bytes32 _hash, bytes32 _nonce, bytes calldata _signature) {
        bool success = paperKeyManager.verify(_hash, _nonce, _signature);
        require(success, "Unauthorized");
        _;
    }

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
        address _crossmintAddress,
        address _paperAddress,
        string memory _provenance,
        Token memory _token
    ) ERC721A(_name, _symbol)
      PaymentSplitter(_payees, _shares) {
        provenance = _provenance;
        baseURI = _uri;
        token = _token;
        crossmintManager = _crossmintAddress;
        paperKeyManager = IPaperKeyManager(_paperAddress);
        transferOwnership(_owner);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function registerPaperKey(address _paperKey) external onlyOwner {
        require(paperKeyManager.register(_paperKey), "Paper error");
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

    function lockSupply() external onlyOwner {
        token.supplyLock = true;
    }

    function updateConfig(
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
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
    }

    function setReferralFee(uint8 _percent) external onlyOwner {
        require(_percent <= 100, "Invalid fee");
        referralFee = _percent;
    }

    function setReferalBonus(uint8 _percent, address _referrer) external onlyOwner {
        require((_percent + referralFee) <= 100, "Invalid fee");
        referrers[_referrer] = _percent;
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
        require(_preSalePhase == 0 || _preSalePhase == 1 || _preSalePhase == 2, "Invalid phase");
        if (_preSaleIsActive && _preSalePhase == 1) require(address(mintpass) != address(0), "MintPass undefined");
        if (_preSaleIsActive && _preSalePhase == 2) require(saleMerkleRoot != "", "Root undefined");
        if (_claimIsActive) require(claimMerkleRoot != "", "Root undefined");
        token.preSaleIsActive = _preSaleIsActive;
        token.pubSaleIsActive = _pubSaleIsActive;
        token.preSalePhase = _preSalePhase;
        token.claimIsActive = _claimIsActive;
    }

    function checkClaimEligibility(address _address, uint256 _quantity, bytes32[] memory _proof) public view returns (string memory) {
        (bool _isEligiblePreSale, bool _isEligiblePubSale) = isEligible(_address, uint16(_quantity), _proof);
        if (!_isEligiblePreSale && !_isEligiblePubSale) return "Not live";
        return "";
    }

    function isEligible(
        address _address,
        uint16 _quantity,
        bytes32[] memory _proof
    ) internal view returns (bool, bool) {
        bool _isEligiblePreSale;
        bool _isEligiblePubSale;
        bool hasSupply = uint16(totalSupply()) + _quantity <= token.maxSupply;
        if(token.preSaleIsActive) {
            if (token.preSalePhase == 1) {
                _isEligiblePreSale = hasSupply && mintpass.balanceOf(_address, 1) >= _quantity;
            }
            if (token.preSalePhase == 2) {
                bytes32 leaf = keccak256(abi.encodePacked(_address));
                _isEligiblePreSale = hasSupply && 
                    MerkleProof.verify(_proof, saleMerkleRoot, leaf) && 
                    (hasMinted[_address] + _quantity) <= token.maxPerWallet;
            }
        }
        if (token.pubSaleIsActive) {
            _isEligiblePubSale = hasSupply && _quantity <= token.maxPerTransaction;
        }
        return (_isEligiblePreSale, _isEligiblePubSale);
    }

    function _payReferral(address _recipient, address payable _referrer, uint256 _quantity, uint256 _value) internal {
        if (_referrer != address(0) && _referrer != _recipient) {
            uint256 _commission = _value * (referralFee + referrers[_referrer]) / 100;
            emit Referral(_referrer, _quantity, _commission);
            (bool sent,) = _referrer.call{value: _commission}("");
            require(sent, "Failed to send");
        }
    }

    function _mintTo(
        address _address,
        uint256 _quantity,
        bytes32[] memory _proof,
        address payable _referrer,
        uint256 _value
    ) internal {
        (bool _isEligiblePreSale, bool _isEligiblePubSale) = isEligible(_address, uint16(_quantity), _proof);
        require(_isEligiblePreSale || _isEligiblePubSale, "Not eligible");
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
        _payReferral(_address, _referrer, _quantity, _value);
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

    function paper(address _address, uint256 _quantity, bytes32[] memory _proof, address payable _referrer, bytes32 _nonce, bytes calldata _signature) public payable 
        nonReentrant onlyPaper(keccak256(abi.encode(_address, _quantity, _proof, _referrer)), _nonce, _signature)
    {
        _mintTo(_address, _quantity, _proof, _referrer, msg.value);
    }

    function claim(uint16 _maxMint, uint16 _quantity, bytes32[] memory _proof) external {
        require(token.claimIsActive, "Claim inactive");
        require(uint16(totalSupply()) + _quantity <= token.maxSupply, "Insufficient supply");
        uint16 _hasClaimed = hasClaimed[msg.sender];
        bytes32 leaf = keccak256(abi.encode(msg.sender, _maxMint));
        require(MerkleProof.verify(_proof, claimMerkleRoot, leaf), "Not allowlisted");
        uint16 _claimable = _maxMint - _hasClaimed;
        require(_quantity <= _claimable, "Invalid quantity");
        hasClaimed[msg.sender] = _hasClaimed + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserve(address _address, uint16 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= token.maxSupply, "Insufficient supply");
        _safeMint(_address, _quantity);
    }
}