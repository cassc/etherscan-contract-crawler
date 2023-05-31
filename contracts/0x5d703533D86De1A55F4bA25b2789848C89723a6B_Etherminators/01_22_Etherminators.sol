// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//    ___ _____ _  _ ___ ___ __  __ ___ _  _   _ _____ ___  ___  ___
//   | __|_   _| || | __| _ \  \/  |_ _| \| | /_\_   _/ _ \| _ \/ __|
//   | _|  | | | __ | _||   / |\/| || || .` |/ _ \| || (_) |   /\__ \
//   |___| |_| |_||_|___|_|_\_|  |_|___|_|\_/_/ \_\_| \___/|_|_\|___/

// Creator @alwoenie
// Developer @nftchef

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721SeqEnumerable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//----------------------------------------------------------------------------
// OpenSea proxy
//----------------------------------------------------------------------------
import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//----------------------------------------------------------------------------
// Main contract
//----------------------------------------------------------------------------

contract Etherminators is
    ERC721SeqEnumerable,
    ContextMixin,
    NativeMetaTransaction,
    Ownable,
    Pausable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;

    uint128 public PUBLIC_SUPPLY = 6904; // Reserve 65
    uint128 public MAX_SUPPLY = 6969;
    uint128 public PUBLIC_MINT_LIMIT = 10;
    uint128 public PRESALE_MINT_LIMIT = 5;
    int256 public priceTier;
    uint256 public tierLimit = 1000;

    // @dev enforce a per-address lifetime limit based on the mintBalances mapping
    bool public publicWalletLimit = true;
    bool public isPresale = true;
    bool public isRevealed = false;

    mapping(address => uint256) public mintBalances;
    mapping(uint256 => uint256) public pricelist;

    string internal baseTokenURI;
    address[] internal payees;
    address internal _SIGNER;
    string public PROVENANCE_HASH; // keccak256

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    constructor(
        string memory _initialURI,
        address[] memory _payees,
        uint256[] memory _shares,
        address proxyRegistryAddress
    )
        payable
        ERC721Sequencial("ETHERMINATORS", "CSM")
        Pausable()
        PaymentSplitter(_payees, _shares)
    {
        _pause();
        baseTokenURI = _initialURI;
        payees = _payees;

        // @dev: initialize the base price tiers
        pricelist[0] = 0.03 ether;
        pricelist[1] = 0.05 ether;

        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712("ETHERMINATORS");
    }

    function purchase(uint256 _quantity)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(!isPresale, "Presale only.");
        require(
            _quantity <= PUBLIC_MINT_LIMIT,
            "Quantity exceeds PUBLIC_MINT_LIMIT"
        );
        if (publicWalletLimit) {
            require(
                _quantity + mintBalances[msg.sender] <= PUBLIC_MINT_LIMIT,
                "Quantity exceeds per-wallet limit"
            );
        }

        _mint(_quantity);
    }

    function presalePurchase(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) external payable nonReentrant whenNotPaused {
        require(
            checkHash(_hash, _signature, _SIGNER),
            "Address is not on Presale List"
        );
        // @dev Presale always enforces a per-wallet limit
        require(
            _quantity + mintBalances[msg.sender] <= PRESALE_MINT_LIMIT,
            "Quantity exceeds per-wallet limit"
        );

        _mint(_quantity);
    }

    function _mint(uint256 _quantity) internal {
        uint256 currentPrice = _owners.length < tierLimit
            ? pricelist[0]
            : pricelist[1];

        require(msg.value >= currentPrice * _quantity, "Not enough minerals");

        require(
            _quantity + _owners.length <= PUBLIC_SUPPLY,
            "Purchase exceeds available supply"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender);
        }

        // @dev: contract state housekeeping
        mintBalances[msg.sender] += _quantity;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        // @dev: The revealed URI does not add a `/` or a file extesion.
        return
            isRevealed
                ? string(abi.encodePacked(baseTokenURI, tokenId.toString()))
                : baseTokenURI;
    }

    function senderMessageHash() internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(address(this), msg.sender))
            )
        );
        return message;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function checkHash(
        bytes32 _hash,
        bytes memory signature,
        address _account
    ) internal view returns (bool) {
        bytes32 senderHash = senderMessageHash();
        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(signature) == _account;
    }

    /**
     * Convinience function for checking the current price tier
     */
    function getCurrentPrice() external view returns (uint256) {
        return _owners.length < tierLimit ? pricelist[0] : pricelist[1];
    }

    //----------------------------------------------------------------------------
    // Only Owner
    //----------------------------------------------------------------------------

    function setSigner(address _address) external onlyOwner {
        _SIGNER = _address;
    }

    // @dev gift a single token to each address passed in through calldata
    // @param _recipients Array of addresses to send a single token to
    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + _owners.length <= MAX_SUPPLY,
            "_quantity exceeds supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i]);
        }
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function updatePricing(uint256 _tier, uint256 _price) external onlyOwner {
        pricelist[_tier] = _price;
    }

    function updateTierCutoff(uint256 _limit) external onlyOwner {
        tierLimit = _limit;
    }

    function setPresale(bool _state) external onlyOwner {
        isPresale = _state;
    }

    function setPresaleLimit(uint128 _limit) external onlyOwner {
        PRESALE_MINT_LIMIT = _limit;
    }

    function setPublicLimit(uint128 _limit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _limit;
    }

    function setWalletLimit(bool _state) external onlyOwner {
        publicWalletLimit = _state;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function setReveal(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
}