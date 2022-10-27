// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./IERC721Bedu2117Upgradeable.sol";
import "./IERC721KeyPassUAEUpgradeable.sol";

contract SwapERC721Bedu2117Upgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // Swap contract config params
    uint256 private constant _TOKEN_LIMIT_PER_CLAIM_TRANSACTION = 30;
    address private _erc721Bedu2117Address;
    address private _erc721KeyPassAddress;
    address private _trustedSignerAddress;
    address private _trustedRecipientAddress;

    // Swap contract stats params
    uint256 private _statsTokenAmount;
    uint256 private _statsEthAmount;
    uint256 private _statsUsedKeyPassTokenAmount;

    // Mapping for used nonces
    mapping(uint256 => bool) private _usedNonces;
    // Mapping for used key pass token ids by addresses
    mapping(uint256 => address) private _usedKeyPassTokenIds;
    // Mapping for received tokens
    mapping(address => uint256) private _receivedTokens;

    // Emitted when `trustedSignerAddress` updated
    event TrustedSignerAddressUpdated(address trustedSignerAddress);
    // Emitted when `trustedRecipientAddress` updated
    event TrustedRecipientAddressUpdated(address trustedRecipientAddress);

    // Emitted when `payer` claim tokens for `receiver`
    event TokenClaimed(address indexed payer, address indexed receiver, uint256 indexed nonce, uint256 tokenAmount, uint256 ethAmount);

    // Emitted when `ethAmount` withdrawn to `account`
    event EthWithdrawn(address account, uint256 ethAmount);

    function initialize(
        address erc721Bedu2117Address_,
        address erc721KeyPassAddress_,
        address trustedSignerAddress_,
        address trustedRecipientAddress_
    ) public virtual initializer {
        __SwapERC721Bedu2117_init(
            erc721Bedu2117Address_,
            erc721KeyPassAddress_,
            trustedSignerAddress_,
            trustedRecipientAddress_
        );
    }

    function __SwapERC721Bedu2117_init(
        address erc721Bedu2117Address_,
        address erc721KeyPassAddress_,
        address trustedSignerAddress_,
        address trustedRecipientAddress_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapERC721Bedu2117_init_unchained(
            erc721Bedu2117Address_,
            erc721KeyPassAddress_,
            trustedSignerAddress_,
            trustedRecipientAddress_
        );
    }

    function __SwapERC721Bedu2117_init_unchained(
        address erc721Bedu2117Address_,
        address erc721KeyPassAddress_,
        address trustedSignerAddress_,
        address trustedRecipientAddress_
    ) internal initializer {
        require(erc721Bedu2117Address_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(erc721KeyPassAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(trustedSignerAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(trustedRecipientAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        _erc721Bedu2117Address = erc721Bedu2117Address_;
        _erc721KeyPassAddress = erc721KeyPassAddress_;
        _trustedSignerAddress = trustedSignerAddress_;
        _trustedRecipientAddress = trustedRecipientAddress_;
    }

    function config() external view virtual returns (
        address erc721Bedu2117Address,
        address erc721KeyPassAddress,
        address trustedSignerAddress,
        address trustedRecipientAddress,
        uint256 tokenLimitPerClaimTransaction
    ) {
        return (
            _erc721Bedu2117Address,
            _erc721KeyPassAddress,
            _trustedSignerAddress,
            _trustedRecipientAddress,
            _TOKEN_LIMIT_PER_CLAIM_TRANSACTION
        );
    }

    function stats() external view virtual returns (
        uint256 statsTokenAmount,
        uint256 statsEthAmount,
        uint256 statsUsedKeyPassTokenAmount
    ) {
        return (
            _statsTokenAmount,
            _statsEthAmount,
            _statsUsedKeyPassTokenAmount
        );
    }

    function checkNonceUsage(uint256 nonce_) external view virtual returns (bool) {
        return _usedNonces[nonce_];
    }

    function checkKeyPassTokensUsageAddressesBatch(uint256[] memory keyPassTokenIds_) external view virtual returns (address[] memory keyPassTokenIdUsageAddresses) {
        keyPassTokenIdUsageAddresses = new address[](keyPassTokenIds_.length);
        for (uint256 i = 0; i < keyPassTokenIds_.length; ++i) {
            keyPassTokenIdUsageAddresses[i] = _usedKeyPassTokenIds[keyPassTokenIds_[i]];
        }
        return (
            keyPassTokenIdUsageAddresses
        );
    }

    function receivedTokens(address account_) external view virtual returns (uint256) {
        return _receivedTokens[account_];
    }

    function getHolderKeyPassTokensUsage(address keyPassHolder_) external view virtual returns (uint256[] memory keyPassTokenIds, bool[] memory keyPassTokenIdUsages) {
        require(keyPassHolder_ != address(0), "SwapERC721Bedu2117: invalid address");
        uint256 keyPassHolderBalance = IERC721KeyPassUAEUpgradeable(_erc721KeyPassAddress).balanceOf(keyPassHolder_);
        keyPassTokenIds = new uint256[](keyPassHolderBalance);
        keyPassTokenIdUsages = new bool[](keyPassHolderBalance);
        for (uint256 i = 0; i < keyPassHolderBalance; ++i) {
            keyPassTokenIds[i] = IERC721KeyPassUAEUpgradeable(_erc721KeyPassAddress).tokenOfOwnerByIndex(keyPassHolder_, i);
            keyPassTokenIdUsages[i] = _usedKeyPassTokenIds[keyPassTokenIds[i]] != address(0);
        }
        return (
            keyPassTokenIds,
            keyPassTokenIdUsages
        );
    }

    function checkBeforeClaim(
        address payer_,
        address receiver_,
        uint256 tokenAmount_
    ) public view virtual returns (bool) {
        // validate params
        require(payer_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(receiver_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(tokenAmount_ >= 0 && tokenAmount_ <= _TOKEN_LIMIT_PER_CLAIM_TRANSACTION, "SwapERC721Bedu2117: invalid token amount");
        // check contracts params
        require(!paused(), "SwapERC721Bedu2117: contract is paused");
        (bool mintingEnabled, ,) = IERC721Bedu2117Upgradeable(_erc721Bedu2117Address).getContractWorkModes();
        require(mintingEnabled, "SwapERC721Bedu2117: erc721 minting is disabled");
        require(IERC721Bedu2117Upgradeable(_erc721Bedu2117Address).isTrustedMinter(address(this)), "SwapERC721Bedu2117: erc721 wrong trusted minter");
        return true;
    }

    function checkBeforeClaimByKeyPassHolder(
        address payer_,
        address keyPassHolder_,
        uint256[] memory keyPassTokenIds_
    ) public view virtual returns (bool) {
        // validate params
        require(payer_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(keyPassHolder_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(keyPassTokenIds_.length >= 0 && keyPassTokenIds_.length <= _TOKEN_LIMIT_PER_CLAIM_TRANSACTION, "SwapERC721Bedu2117: invalid token ids length");
        // check contracts params
        require(!paused(), "SwapERC721Bedu2117: contract is paused");
        (bool mintingEnabled, ,) = IERC721Bedu2117Upgradeable(_erc721Bedu2117Address).getContractWorkModes();
        require(mintingEnabled, "SwapERC721Bedu2117: erc721 minting is disabled");
        require(IERC721Bedu2117Upgradeable(_erc721Bedu2117Address).isTrustedMinter(address(this)), "SwapERC721Bedu2117: erc721 wrong trusted minter");
        // confirm token ownership and verify usage
        for (uint256 i = 0; i < keyPassTokenIds_.length; ++i) {
            require(IERC721KeyPassUAEUpgradeable(_erc721KeyPassAddress).ownerOf(keyPassTokenIds_[i]) == keyPassHolder_, "SwapERC721Bedu2117: key pass token has another owner");
            require(_usedKeyPassTokenIds[keyPassTokenIds_[i]] == address(0), "SwapERC721Bedu2117: key pass token is already used");
        }
        return true;
    }

    function claimToken(
        address receiver_,
        uint256 tokenAmount_,
        uint256 ethAmount_,
        uint256 nonce_,
        uint256 salt_,
        uint256 maxBlockNumber_,
        bytes memory signature_
    ) external virtual payable nonReentrant whenNotPaused {
        // check signature
        bytes32 hash = keccak256(abi.encodePacked(_msgSender(), "/", receiver_, "/", tokenAmount_, "/", ethAmount_, "/", nonce_, "/", salt_, "/", maxBlockNumber_));
        address signer = hash.toEthSignedMessageHash().recover(signature_);
        require(signer == _trustedSignerAddress, "SwapERC721Bedu2117: invalid signature");
        // check max block limit
        require(block.number <= maxBlockNumber_, "SwapERC721Bedu2117: failed max block check");
        // claim tokens
        _claimToken(_msgSender(), receiver_, tokenAmount_, ethAmount_, nonce_);
    }

    function claimTokenByKeyPassHolder(
        address keyPassHolder_,
        uint256[] memory keyPassTokenIds_,
        uint256 ethAmount_,
        uint256 nonce_,
        uint256 salt_,
        uint256 maxBlockNumber_,
        bytes memory signature_
    ) external virtual payable nonReentrant whenNotPaused {
        // check signature
        bytes32 hash = keccak256(abi.encodePacked(_msgSender(), "/", keyPassHolder_, "/", keyPassTokenIds_, "/", ethAmount_, "/", nonce_, "/", salt_, "/", maxBlockNumber_));
        address signer = hash.toEthSignedMessageHash().recover(signature_);
        require(signer == _trustedSignerAddress, "SwapERC721Bedu2117: invalid signature");
        // check max block limit
        require(block.number <= maxBlockNumber_, "SwapERC721Bedu2117: failed max block check");
        // claim tokens
        _claimTokenByKeyPassHolder(_msgSender(), keyPassHolder_, keyPassTokenIds_, ethAmount_, nonce_);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateTrustedSignerAddress(address trustedSignerAddress_) external virtual onlyOwner {
        require(trustedSignerAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        _trustedSignerAddress = trustedSignerAddress_;
        emit TrustedSignerAddressUpdated(trustedSignerAddress_);
    }

    function updateTrustedRecipientAddress(address trustedRecipientAddress_) external virtual onlyOwner {
        require(trustedRecipientAddress_ != address(0), "SwapERC721Bedu2117: invalid address");
        _trustedRecipientAddress = trustedRecipientAddress_;
        emit TrustedRecipientAddressUpdated(trustedRecipientAddress_);
    }

    function withdrawEth(address payable account_, uint256 ethAmount_) external virtual onlyOwner {
        require(account_ != address(0), "SwapERC721Bedu2117: invalid address");
        require(ethAmount_ != 0, "SwapERC721Bedu2117: invalid amount");
        AddressUpgradeable.sendValue(account_, ethAmount_);
        emit EthWithdrawn(account_, ethAmount_);
    }

    function _claimToken(
        address payer_,
        address receiver_,
        uint256 tokenAmount_,
        uint256 ethAmount_,
        uint256 nonce_
    ) internal virtual {
        // check before claim
        checkBeforeClaim(payer_, receiver_, tokenAmount_);
        // check eth amount
        require(ethAmount_ == msg.value, "SwapERC721Bedu2117: invalid ETH amount");
        // check nonce usage
        require(!_usedNonces[nonce_], "SwapERC721Bedu2117: current nonce is already used");
        // update nonce usage
        _usedNonces[nonce_] = true;
        // update received tokens
        _receivedTokens[receiver_] += tokenAmount_;
        // update stats params
        _statsTokenAmount += tokenAmount_;
        _statsEthAmount += ethAmount_;
        // mint erc721 tokens
        IERC721Bedu2117Upgradeable(_erc721Bedu2117Address).mintTokenBatchByTrustedMinter(receiver_, tokenAmount_);
        emit TokenClaimed(payer_, receiver_, nonce_, tokenAmount_, ethAmount_);
    }

    function _claimTokenByKeyPassHolder(
        address payer_,
        address keyPassHolder_,
        uint256[] memory keyPassTokenIds_,
        uint256 ethAmount_,
        uint256 nonce_
    ) internal virtual {
        // check before claim
        checkBeforeClaimByKeyPassHolder(payer_, keyPassHolder_, keyPassTokenIds_);
        // check eth amount
        require(ethAmount_ == msg.value, "SwapERC721Bedu2117: invalid ETH amount");
        // check nonce usage
        require(!_usedNonces[nonce_], "SwapERC721Bedu2117: current nonce is already used");
        // update nonce usage
        _usedNonces[nonce_] = true;
        // update key pass tokens usage and calculate tokenAmount
        uint256 tokenAmount;
        for (uint256 i = 0; i < keyPassTokenIds_.length; ++i) {
            if (_usedKeyPassTokenIds[keyPassTokenIds_[i]] == address(0)) {
                _usedKeyPassTokenIds[keyPassTokenIds_[i]] = keyPassHolder_;
                tokenAmount++;
            }
        }
        require(tokenAmount != 0, "SwapERC721Bedu2117: no key pass tokens for use");
        // update received tokens
        _receivedTokens[keyPassHolder_] += tokenAmount;
        // update stats params
        _statsTokenAmount += tokenAmount;
        _statsEthAmount += ethAmount_;
        _statsUsedKeyPassTokenAmount += tokenAmount;
        // mint erc721 tokens
        IERC721Bedu2117Upgradeable(_erc721Bedu2117Address).mintTokenBatchByTrustedMinter(keyPassHolder_, tokenAmount);
        emit TokenClaimed(payer_, keyPassHolder_, nonce_, tokenAmount, ethAmount_);
    }
}