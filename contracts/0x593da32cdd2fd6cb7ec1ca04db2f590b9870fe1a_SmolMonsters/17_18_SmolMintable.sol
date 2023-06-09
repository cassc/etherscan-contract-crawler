// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibValidator.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Tokens can only be minted by Whitelisted Wallets if whitelist is activated.
// Once whitelist is disabled, minting is enabled for Everyone

abstract contract SmolMintable is Context, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    // TODO Whitelist, Public Mint Pausable
    address public validatorWallet;
    address public payoutWallet;
    bool public whitelistEnabled;
    bool public publicMintEnabled;
    Counters.Counter public _tokenIdTracker;
    
    uint256 public _tokenLimit;
    uint256 public _maxTokensPerWhitelistWallet;
    uint256 public _maxTokensPerWallet;
    uint256 public _maxTokensPerTransactionPublic;
    uint256 public _maxTokensPerTransactionWhitelist;

    uint256 public pricePerToken;
    uint256 public pricePerTokenTier1;
    uint256 public pricePerTokenTier2;
    uint256 public pricePerTokenTier3;
    uint256 public pricePerTokenTier4;

    mapping(address => uint256) public boughtAmounts;
    mapping(address => mapping (address => uint256)) public boughtWhitelistAmounts;

    function setPricePerToken(uint256 _pricePerToken, uint256 _pricePerTokenTier1, uint256 _pricePerTokenTier2, uint256 _pricePerTokenTier3, uint256 _pricePerTokenTier4) public virtual onlyOwner() {
        pricePerToken = _pricePerToken;
        pricePerTokenTier1 = _pricePerTokenTier1;
        pricePerTokenTier2 = _pricePerTokenTier2;
        pricePerTokenTier3 = _pricePerTokenTier3;
        pricePerTokenTier4 = _pricePerTokenTier4;
    }

    function setWhitelistLimits(uint256 maxTokensPerTransactionWhitelist, uint256 maxTokensPerWhitelistWallet) public virtual onlyOwner() {
        _maxTokensPerTransactionWhitelist = maxTokensPerTransactionWhitelist;
        _maxTokensPerWhitelistWallet = maxTokensPerWhitelistWallet;
    }

    // function to set _maxTokensPerTransactionPublic
    function setPublicLimits(uint256 maxTokensPerWallet, uint256 maxTokensPerTransactionPublic) public virtual onlyOwner() {
        _maxTokensPerTransactionPublic = maxTokensPerTransactionPublic;
        _maxTokensPerWallet = maxTokensPerWallet;
    }

    // function to set whitelisteEnabled true / false (default true)
    function setMintEnabled(bool _whitelistEnabled, bool _publicEnabled) public virtual onlyOwner() {
        whitelistEnabled = _whitelistEnabled;
        publicMintEnabled = _publicEnabled;
    }

    // function to change the validator Wallet
    function setValidatorAddress(address validator) public virtual onlyOwner(){
        validatorWallet = validator;
    }

    // function to change the validator Wallet
    function setPayoutWallet(address _wallet) public virtual onlyOwner(){
        payoutWallet = _wallet;
    }


    // publicMint Function (more ore less the same as whitelist mint just without the tier stuff and only if whitelistEnabled is false)
    function publicMint() public payable {

        // check public minting is enabled
        require(publicMintEnabled == true, "SM: Disabled");

        // check token limit is not reached
        require(_tokenLimit >= _tokenIdTracker.current(), "SM: L1");

        uint256 amount = msg.value / pricePerToken;

        // check maxTokensPerWallet limit is not reached
        require(boughtAmounts[msg.sender] + amount <= _maxTokensPerWallet, "SM: L2");

        if (amount > _maxTokensPerTransactionPublic) {
            amount = _maxTokensPerTransactionPublic;
        }

        // check token limit is not reached with requested amount
        require(_tokenLimit >= (_tokenIdTracker.current() + amount), "SM: L3");
        
        uint j;
        while (j < amount) {
            _mint(msg.sender, _tokenIdTracker.current());
            _tokenIdTracker.increment();
            boughtAmounts[msg.sender] = boughtAmounts[msg.sender] + 1;
            j++;
        }
        payable(payoutWallet).transfer(msg.value);
    }

    // function to mint only to whitelisted addresses
    function whitelistMint(string memory tier, bytes memory validator ) public payable {

        // check public minting is enabled
        require(whitelistEnabled == true, "SM: Disabled");

        // check token limit is not reached
        require(_tokenLimit >= _tokenIdTracker.current(), "SM: L1");
        
        string memory addressString = string(abi.encodePacked(LibValidator.addressToAsciiString(msg.sender), tier));
        bytes32 validationString = keccak256(abi.encodePacked(addressString));
        bytes32 validationHash = ECDSA.toEthSignedMessageHash(validationString);
        address signer = ECDSA.recover(validationHash, validator);
        require(signer == validatorWallet, "SM: Signature");

        // set default value
        uint256 _pricePerToken = pricePerToken;

        if (keccak256(abi.encodePacked(tier)) == keccak256("level_1") && (msg.value / _pricePerToken) >= 2) _pricePerToken = pricePerTokenTier1;
        if (keccak256(abi.encodePacked(tier)) == keccak256("level_2")) _pricePerToken = pricePerTokenTier2;
        if (keccak256(abi.encodePacked(tier)) == keccak256("level_3")) _pricePerToken = pricePerTokenTier3;
        if (keccak256(abi.encodePacked(tier)) == keccak256("level_4")) _pricePerToken = pricePerTokenTier4;

        uint256 amount = msg.value / _pricePerToken;

        // check maxTokensPerWallet limit is not reached
        require(boughtWhitelistAmounts[validatorWallet][msg.sender] + amount <= _maxTokensPerWhitelistWallet, "SM: L2");


        if (amount > _maxTokensPerTransactionWhitelist) {
            amount = _maxTokensPerTransactionWhitelist;
        }

        require(_tokenLimit >= (_tokenIdTracker.current() + amount), "SM: L3");

        uint j;
        while (j < amount) {
            _mint(msg.sender, _tokenIdTracker.current());
            _tokenIdTracker.increment();
            boughtWhitelistAmounts[validatorWallet][msg.sender] = boughtWhitelistAmounts[validatorWallet][msg.sender] + 1;
            j++;
        }

        payable(payoutWallet).transfer(msg.value);
    }

    function mint(address to) public virtual onlyOwner {
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

}