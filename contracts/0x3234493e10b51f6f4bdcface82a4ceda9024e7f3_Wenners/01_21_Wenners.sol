// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "refer2earn/Referable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./opensea/DefaultOperatorFilterer.sol";
import "./IMintPass.sol";
import "./IERC2981.sol";
import "./IDelegationRegistry.sol";

contract Wenners is ERC721A, Ownable, PaymentSplitter, DefaultOperatorFilterer, ReentrancyGuard, Referable, IERC2981 {

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
        uint8 preSalePhase;
        bool supplyLock;
        bool refer2earn;
    }

    struct Eligible {
        bool claim;
        bool preSale;
        bool pubSale;
    }

    mapping(address => uint16) public hasClaimed;
    mapping(address => uint16) public hasMinted;
    mapping(address => bool) public fiatMinters;
    Token public token;
    string private baseURI;
    IMintPass public mintpass;
    string public provenance;
    bytes32 public saleMerkleRoot;
    bytes32 public claimMerkleRoot;
    RoyaltyInfo royalties;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        address[] memory _interfaces, // 0 = refer2earn, 1 = delegate.cash, 2 = crossmint
        string memory _provenance,
        Token memory _token,
        RoyaltyInfo memory _royalties
    ) ERC721A(_name, _symbol)
      Referable(_interfaces[0])
      PaymentSplitter(_payees, _shares) {
        provenance = _provenance;
        baseURI = _uri;
        token = _token;
        royalties = _royalties;
        dc = IDelegationRegistry(_interfaces[1]);
        fiatMinters[_interfaces[2]] = true;
        transferOwnership(_owner);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        require((!token.preSaleIsActive && !token.pubSaleIsActive) || totalSupply() == token.maxSupply || token.supplyLock, "Can't list");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) payable public override onlyAllowedOperatorApproval(operator) {
        require((!token.preSaleIsActive && !token.pubSaleIsActive) || totalSupply() == token.maxSupply  || token.supplyLock, "Can't list");
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

    function setMintPass(address _address) external onlyOwner {
        mintpass = IMintPass(_address);
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
        bool _pubPerWallet
    ) external onlyOwner {
        if (token.supplyLock) require(_maxSupply == token.maxSupply, "Locked");
        require(_pubMaxMint <= 50, "Too many");
        require(_maxSupply >= totalSupply(), "Invalid supply");
        token.maxSupply = _maxSupply;
        token.pubMaxMint = _pubMaxMint;
        token.pubPerWallet = _pubPerWallet;
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function updateSaleState(
        bool _preSaleIsActive,
        bool _pubSaleIsActive,
        bool _claimIsActive,
        uint8 _preSalePhase,
        bool _refer2earn
    ) external onlyOwner {
        require(_preSalePhase == 0 || _preSalePhase == 1 || _preSalePhase == 2, "Bad phase");
        if (_preSaleIsActive && _preSalePhase == 1) require(address(mintpass) != address(0), "MintPass undefined");
        if (_preSaleIsActive && _preSalePhase == 2) require(saleMerkleRoot != "", "Root undefined");
        if (_claimIsActive) require(claimMerkleRoot != "", "Root undefined");
        token.preSaleIsActive = _preSaleIsActive;
        token.pubSaleIsActive = _pubSaleIsActive;
        token.claimIsActive = _claimIsActive;
        token.preSalePhase = _preSalePhase;
        token.refer2earn = _refer2earn;
    }

    function isEligible(
        address _address,
        uint16 _quantity,
        uint16 _maxMint,
        bytes32[] memory _proof,
        uint256 _value
    ) internal returns (Eligible memory) {
        Eligible memory _isEligible;
        uint16 _hasMinted = hasMinted[_address];
        uint16 _hasClaimed = hasClaimed[_address];
        if(token.claimIsActive && _value == 0 && (_quantity <= (_maxMint - _hasClaimed))) {
            bytes32 _leaf = keccak256(abi.encode(_address, _maxMint));
            _isEligible.claim = MerkleProof.verify(_proof, claimMerkleRoot, _leaf);
            if (_isEligible.claim) hasClaimed[_address] += _quantity;
        }
        if(!_isEligible.claim && (_value == token.preSalePrice * _quantity) && token.preSaleIsActive && (_quantity <= _maxMint - _hasMinted)) {
            if (token.preSalePhase == 1) {
                _isEligible.preSale = mintpass.balanceOf(_address, 1) >= _quantity;
            }
            if (token.preSalePhase == 2 && (_quantity <= _maxMint - _hasMinted)) {
                bytes32 _leaf = keccak256(abi.encode(_address, _maxMint));
                _isEligible.preSale = MerkleProof.verify(_proof, saleMerkleRoot, _leaf);
            }
            if (_isEligible.preSale) hasMinted[_address] += _quantity;
        }
        if (!_isEligible.claim && !_isEligible.preSale && token.pubSaleIsActive && (_value == token.pubSalePrice * _quantity)) {
            if (token.pubPerWallet) {
                _isEligible.pubSale = (_quantity <= (token.pubMaxMint - _hasMinted));
            } else {
                _isEligible.pubSale = (_quantity <= token.pubMaxMint);
            }
            if (_isEligible.pubSale && (token.pubPerWallet)) hasMinted[_address] += _quantity;
        }
        return _isEligible;
    }

    function mint(
        address _address,
        uint256 _quantity,
        uint256 _maxMint,
        bytes32[] memory _proof,
        address payable _referrer
    ) external payable nonReentrant {
        require(_address != address(0), "Bad address");
        if (_address != msg.sender) require((fiatMinters[msg.sender] || dc.checkDelegateForContract(msg.sender, _address, address(this))), "Unauthorized");
        require(totalSupply() + _quantity <= token.maxSupply, "No supply");
        (Eligible memory _isEligible) = isEligible(_address, uint16(_quantity), uint16(_maxMint), _proof, msg.value);
        require(_isEligible.claim || _isEligible.preSale || _isEligible.pubSale, "Ineligible");
        _safeMint(_address, _quantity);
        if (token.refer2earn) Referable.payReferral(_address, _referrer, _quantity, msg.value);
    }

    function setRoyalties(uint256 _id, address recipient, uint256 _basisPoints) public onlyOwner {
        royalties = RoyaltyInfo(recipient, uint24(_basisPoints));
    }

    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royalties.recipient, (_salePrice * royalties.basisPoints) / 10000);
    }

    function airdrop(address[] memory _addresses, uint16[] memory _quantities) external onlyOwner {
        require(_addresses.length > 0, "Invalid");
        require(_addresses.length == _quantities.length, "Invalid");
        uint16 _quantity;
        for (uint256 i; i < _quantities.length; i++) {
            require(_quantities[i] <= 50, "Too many");
            _quantity += _quantities[i];
        }
        require(totalSupply() + _quantity <= token.maxSupply, "No supply");
        for (uint256 i; i < _addresses.length; i++) _safeMint(_addresses[i], _quantities[i]);
    }
}