// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "refer2earn/Referable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

contract MrdrVrsContract is ERC721A, Ownable, PaymentSplitter, DefaultOperatorFilterer, ReentrancyGuard, Referable, Pausable  {

    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Token {
        uint16 maxSupply;
        PublicMintType pubMintType;
        uint16 pubMaxMint;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool pubSaleIsActive;
        bool claimIsActive;
        bool supplyLock;
    }

    enum PublicMintType { PerWallet, PerTransaction }

    mapping(uint256 => EnumerableSet.AddressSet) private guessers;
    mapping(address => EnumerableSet.UintSet) private guesses;
    mapping(address => uint256) private userIds;
    mapping(address => uint16) public hasClaimed;
    mapping(address => uint16) public hasMinted;
    mapping(address => bool) public fiatMinters;
    Token public token;
    string public provenance;
    uint16 public totalGuesses;
    uint16 public totalMinted;
    bytes32 public saleMerkleRoot;
    bytes32 public claimMerkleRoot;
    string private baseURI;
    bool private refer2earn;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        address _r2eAddress,
        Token memory _token
    ) ERC721A(_name, _symbol)
      Referable(_r2eAddress)
      PaymentSplitter(_payees, _shares) {
        baseURI = _uri;
        token = _token;
        _pause();
        transferOwnership(_owner);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) payable public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setProvenance(string memory hash) external onlyOwner {
        provenance = hash;
    }

    function setRefer2Earn(bool _active) external onlyOwner {
        refer2earn = _active;
    }

    function getGuessers(uint256 _tokenId) external view returns (address[] memory, uint256[] memory) {
        EnumerableSet.AddressSet storage _guessers = guessers[_tokenId];
        address[] memory _addresses = new address[](_guessers.length());
        uint256[] memory _userIds = new uint256[](_guessers.length());
        for (uint256 i; i < _guessers.length(); i++) {
            _addresses[i] = _guessers.at(i);
            _userIds[i] = userIds[_guessers.at(i)];
        }
        return (_addresses, _userIds);
    }

    function getGuesses(address _address) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage _guesses = guesses[_address];
        uint256[] memory tokens = new uint256[](_guesses.length());
        for (uint256 i; i < _guesses.length(); i++) {
            tokens[i] = _guesses.at(i);
        }
        return tokens;
    }

    function lockSupply() external onlyOwner {
        token.supplyLock = true;
    }

    function setFiatMinter(address _address, bool _allowed) external onlyOwner {
        if (_allowed) {
            fiatMinters[_address] = true;
        } else {
            delete fiatMinters[_address];
        }
    }

    function setSaleRoot(bytes32 _root) external onlyOwner {
        saleMerkleRoot = _root;
    }

    function setClaimRoot(bytes32 _root) external onlyOwner {
        claimMerkleRoot = _root;
    }

    function _startTokenId() override internal pure returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function setPrice(
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) external onlyOwner {
        token.preSalePrice = _preSalePrice;
        token.pubSalePrice = _pubSalePrice;
    }

    function updateConfig(
        uint16 _maxSupply,
        uint16 _pubMaxMint,
        PublicMintType _pubMintType
    ) external onlyOwner {
        if (token.supplyLock) require(_maxSupply == token.maxSupply, "Locked");
        require(_pubMaxMint <= 50, "Too many");
        require(_maxSupply >= totalSupply(), "Bad supply");
        token.maxSupply = _maxSupply;
        token.pubMaxMint = _pubMaxMint;
        token.pubMintType = _pubMintType;
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function updateSaleState(
        bool _preSaleIsActive,
        bool _pubSaleIsActive,
        bool _claimIsActive
    ) external onlyOwner {
        if (_preSaleIsActive) require(saleMerkleRoot != "", "Bad root");
        if (_claimIsActive) require(claimMerkleRoot != "", "Bad root");
        token.preSaleIsActive = _preSaleIsActive;
        token.pubSaleIsActive = _pubSaleIsActive;
        token.claimIsActive = _claimIsActive;
    }

    function isEligible(
        address _address,
        uint16 _quantity,
        uint16 _maxMint,
        bytes32[] memory _proof,
        uint256 _value
    ) internal returns (bool, bool, bool) {
        bool _isEligibleClaim;
        bool _isEligiblePreSale;
        bool _isEligiblePubSale;
        bool _hasSupply = totalMinted + _quantity <= token.maxSupply;
        if(token.claimIsActive && (_quantity <= (_maxMint - hasClaimed[_address])) && _value == 0) {
                _isEligibleClaim = _hasSupply && _maxMint <= 50 &&
                    MerkleProof.verify(_proof, claimMerkleRoot, keccak256(abi.encode(_address, _maxMint)));
                if (_isEligibleClaim) hasClaimed[_address] += _quantity;
        }
        if(!_isEligibleClaim && token.preSaleIsActive && (_quantity <= _maxMint - hasMinted[_address]) && (_value == token.preSalePrice * _quantity)) {
                _isEligiblePreSale = _hasSupply && _maxMint <= 50 &&
                    MerkleProof.verify(_proof, saleMerkleRoot, keccak256(abi.encode(_address, _maxMint)));
                if (_isEligiblePreSale) hasMinted[_address] += _quantity;
        }
        if (!_isEligibleClaim && !_isEligiblePreSale && token.pubSaleIsActive && (_value == token.pubSalePrice * _quantity)) {
            if (token.pubMintType == PublicMintType.PerWallet) {
                _isEligiblePubSale = _hasSupply && (_quantity <= (token.pubMaxMint - hasMinted[_address]));
            } else {
                _isEligiblePubSale = _hasSupply && (_quantity <= token.pubMaxMint);
            }
            if (_isEligiblePubSale && (token.pubMintType == PublicMintType.PerWallet)) hasMinted[_address] += _quantity;
        }
        return (_isEligibleClaim, _isEligiblePreSale, _isEligiblePubSale);
    }

    function mint(
        address _address,
        uint256 _quantity,
        uint256 _maxMint,
        bytes32[] memory _proof,
        address payable _referrer
    ) external payable nonReentrant {
        if (_address != msg.sender) require(fiatMinters[msg.sender], "Unauthorized");
        (bool _isEligibleClaim, bool _isEligiblePreSale, bool _isEligiblePubSale) = isEligible(_address, uint16(_quantity), uint16(_maxMint), _proof, msg.value);
        require(_isEligibleClaim || _isEligiblePreSale || _isEligiblePubSale, "Ineligible");
        totalMinted += uint16(_quantity);
        _safeMint(_address, _quantity);
        if (refer2earn) Referable.payReferral(_address, _referrer, _quantity, msg.value);
    }

    function burn(uint256 _burnId, uint256 _guessId, uint256 _userId) public whenNotPaused {
        require(ownerOf(_burnId) == msg.sender, "Not owner");
        require(!guessers[_guessId].contains(msg.sender), "Bad guesser");
        require(!guesses[msg.sender].contains(_guessId), "Bad guess");
        guessers[_guessId].add(msg.sender);
        guesses[msg.sender].add(_guessId);
        if (_userId > 0) userIds[msg.sender] = _userId;
        totalGuesses++;
        _burn(_burnId);
    }

    function tokensOf(address _address) external view returns (uint256[] memory) {
        uint256[] memory _tokens = new uint256[](balanceOf(_address));
        uint256 index;
        for (uint256 i = 1; i <= totalMinted; i++) {
            if (_exists(i) && ownerOf(i) == _address) {
                _tokens[index] = i;
                index++;
            }
        }
        return _tokens;
    }

    function setGameStatus(bool _active) external onlyOwner {
        if (_active) {
            _unpause();
        } else {
            _pause();
        }
    }

    function reset() external onlyOwner {
        provenance = "";
        totalGuesses = 0;
        totalMinted = uint16(totalSupply());
        EnumerableSet.AddressSet storage _guessers;
        address[] memory addresses;
        for (uint256 i = 1; i <= token.maxSupply; i++) {
            _guessers = guessers[i];
            if (_guessers.length() > 0) {
                addresses = guessers[i].values();
                for (uint256 j = 0; j < addresses.length; j++) {
                    if (guesses[addresses[j]].contains(i)) {
                        guesses[addresses[j]].remove(i);
                        guessers[i].remove(addresses[j]);
                        delete userIds[addresses[j]];
                    }
                }
            }
        }
    }

    function airdrop(address[] memory _addresses, uint16[] memory _quantities) external onlyOwner {
        require(_addresses.length > 0, "Invalid");
        require(_addresses.length == _quantities.length, "Invalid");
        uint16 _quantity;
        for (uint256 i; i < _quantities.length; i++) {
            require(_quantities[i] <= 50, "Too many");
            _quantity += _quantities[i];
        }
        totalMinted += _quantity;
        require(totalMinted + _quantity <= token.maxSupply, "No supply");
        for (uint256 i; i < _addresses.length; i++) _safeMint(_addresses[i], _quantities[i]);
    }
}