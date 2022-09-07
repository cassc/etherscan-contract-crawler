// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./IERC721AmbroseUpgradeable.sol";

contract SwapERC721AmbroseUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // Swap ambrose contract address
    address private _erc721AmbroseAddress;
    // Swap trusted signer address
    address private _trustedSignerAddress;

    // Swap payment params
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%
    address[] private _paymentRecipients;
    uint256[] private _paymentPercents;

    // Swap stage params
    uint256 private constant _MAX_PER_CLAIM_LIMIT = 30;
    struct StageData {
        bool mintingEnabled;
        uint256 ethPrice;
        uint256 ethAmount;
        uint256 tokenAmount;
        uint256 tokenAmountLimit;
        uint256 perClaimLimit;
        uint256 perStageLimit;
    }
    mapping(uint256 => StageData) private _stages;
    uint256 private _currentStageId;

    // Mapping from account to claimed stage tokens
    mapping(address => mapping(uint256 => uint256)) private _claimedTokens;

    // Emitted when `trustedSignerAddress` updated
    event TrustedSignerAddressUpdated(address trustedSignerAddress);

    // Emitted when payment params updated
    event PaymentConfigUpdated(address[] paymentRecipients, uint256[] paymentPercents);

    // Emitted when new Stage updated
    event StageUpdated(uint256 stageId, bool mintingEnabled, uint256 ethPrice, uint256 tokenAmountLimit, uint256 perClaimLimit, uint256 perStageLimit);
    // Emitted when current stageId updated
    event CurrentStageUpdated(uint256 stageId);

    // Emitted when `account` receive tokens
    event TokenClaimed(address indexed account, uint256 stageId, uint256 tokenAmount, uint256 ethAmount);

    // Emitted when payments sent to recipients
    event PaymentsSentToRecipients(address[] recipients, uint256[] ethAmounts);

    function initialize(
        address erc721AmbroseAddress_,
        address trustedSignerAddress_,
        address[] memory paymentRecipients_,
        uint256[] memory paymentPercents_
    ) public virtual initializer {
        __SwapERC721Ambrose_init(
            erc721AmbroseAddress_,
            trustedSignerAddress_,
            paymentRecipients_,
            paymentPercents_
        );
    }

    function __SwapERC721Ambrose_init(
        address erc721AmbroseAddress_,
        address trustedSignerAddress_,
        address[] memory paymentRecipients_,
        uint256[] memory paymentPercents_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapERC721Ambrose_init_unchained(
            erc721AmbroseAddress_,
            trustedSignerAddress_,
            paymentRecipients_,
            paymentPercents_
        );
    }

    function __SwapERC721Ambrose_init_unchained(
        address erc721AmbroseAddress_,
        address trustedSignerAddress_,
        address[] memory paymentRecipients_,
        uint256[] memory paymentPercents_
    ) internal initializer {
        require(erc721AmbroseAddress_ != address(0), "SwapERC721Ambrose: invalid address");
        require(trustedSignerAddress_ != address(0), "SwapERC721Ambrose: invalid address");
        _erc721AmbroseAddress = erc721AmbroseAddress_;
        _trustedSignerAddress = trustedSignerAddress_;
        _setPaymentConfig(paymentRecipients_, paymentPercents_);
    }

    function erc721AmbroseAddress() external view virtual returns (address) {
        return _erc721AmbroseAddress;
    }

    function trustedSignerAddress() external view virtual returns (address) {
        return _trustedSignerAddress;
    }

    function paymentConfig() external view virtual returns (address[] memory paymentRecipients, uint256[] memory paymentPercents) {
        return (
            _paymentRecipients,
            _paymentPercents
        );
    }

    function currentStageId() external view virtual returns (uint256) {
        return _currentStageId;
    }

    function getStageInfo(uint256 stageId_)
        external
        view
        virtual
        returns (
            bool mintingEnabled,
            uint256 ethPrice,
            uint256 ethAmount,
            uint256 tokenAmount,
            uint256 tokenAmountLimit,
            uint256 perClaimLimit,
            uint256 perStageLimit
        )
    {
        StageData storage stage = _stages[stageId_];
        return (
            stage.mintingEnabled,
            stage.ethPrice,
            stage.ethAmount,
            stage.tokenAmount,
            stage.tokenAmountLimit,
            stage.perClaimLimit,
            stage.perStageLimit
        );
    }

    function getAddressClaimInfo(address account_, uint256 stageId_) external view virtual returns (uint256) {
        return _claimedTokens[account_][stageId_];
    }

    function checkBeforeClaim(address account_, uint256 stageId_, uint256 tokenAmount_) public view virtual returns (uint256 ethAmount) {
        // validate params
        require(account_ != address(0), "SwapERC721Ambrose: invalid address");
        require(stageId_ == _currentStageId, "SwapERC721Ambrose: invalid stageId");
        require(tokenAmount_ != 0, "SwapERC721Ambrose: invalid token amount");
        // check contracts params
        require(!paused(), "SwapERC721Ambrose: contract is paused");
        require(!IERC721AmbroseUpgradeable(_erc721AmbroseAddress).paused(), "SwapERC721Ambrose: erc721 is paused");
        require(IERC721AmbroseUpgradeable(_erc721AmbroseAddress).isTrustedMinter(address(this)), "SwapERC721Ambrose: erc721 wrong trusted minter");
        // check stage params
        StageData storage stage = _stages[stageId_];
        require(stage.mintingEnabled, "SwapERC721Ambrose: stage minting disabled");
        require((tokenAmount_ + stage.tokenAmount) <= stage.tokenAmountLimit, "SwapERC721Ambrose: token amount limit reached");
        require(tokenAmount_ <= stage.perClaimLimit, "SwapERC721Ambrose: failed per claim limit check");
        require(stage.perStageLimit == 0 || (tokenAmount_ + _claimedTokens[account_][stageId_]) <= stage.perStageLimit, "SwapERC721Ambrose: failed per stage limit check");
        // calculate eth amount
        return stage.ethPrice * tokenAmount_;
    }

    function claimToken(
        uint256 stageId_,
        uint256 tokenAmount_,
        uint256 ethAmount_,
        uint256 nonce_,
        uint256 salt_,
        uint256 maxBlockNumber_,
        bytes memory signature_
    ) external virtual payable nonReentrant whenNotPaused {
        // check signature
        bytes32 hash = keccak256(abi.encodePacked(_msgSender(), stageId_, tokenAmount_, ethAmount_, nonce_, salt_, maxBlockNumber_));
        address signer = hash.toEthSignedMessageHash().recover(signature_);
        require(signer == _trustedSignerAddress, "SwapERC721Ambrose: invalid signature");
        // check max block limit
        require(block.number <= maxBlockNumber_, "SwapERC721Ambrose: failed max block check");
        // claim tokens
        _claimToken(_msgSender(), stageId_, tokenAmount_, ethAmount_);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateTrustedSignerAddress(address trustedSignerAddress_) external virtual onlyOwner {
        require(trustedSignerAddress_ != address(0), "SwapERC721Ambrose: invalid address");
        _trustedSignerAddress = trustedSignerAddress_;
        emit TrustedSignerAddressUpdated(trustedSignerAddress_);
    }

    function updatePaymentConfig(address[] memory paymentRecipients_, uint256[] memory paymentPercents_) external virtual onlyOwner {
        _setPaymentConfig(paymentRecipients_, paymentPercents_);
    }

    function updateCurrentStageId(uint256 stageId_) external virtual onlyOwner {
        _currentStageId = stageId_;
        emit CurrentStageUpdated(stageId_);
    }

    function updateStage(uint256 stageId_, bool mintingEnabled_, uint256 ethPrice_, uint256 tokenAmountLimit_, uint256 perClaimLimit_, uint256 perStageLimit_) external virtual onlyOwner {
        require(stageId_ != 0, "SwapERC721Ambrose: invalid stageId");
        require(ethPrice_ != 0, "SwapERC721Ambrose: invalid eth price");
        require(perClaimLimit_ > 0 && perClaimLimit_ <= _MAX_PER_CLAIM_LIMIT, "SwapERC721Ambrose: invalid per claim limit");
        require(perStageLimit_ == 0 || perClaimLimit_ <= perStageLimit_, "SwapERC721Ambrose: invalid per stage limit");
        StageData storage stage = _stages[stageId_];
        require(tokenAmountLimit_ > 0 && tokenAmountLimit_ >= stage.tokenAmount, "SwapERC721Ambrose: invalid token amount limit");
        stage.mintingEnabled = mintingEnabled_;
        stage.ethPrice = ethPrice_;
        stage.tokenAmountLimit = tokenAmountLimit_;
        stage.perClaimLimit = perClaimLimit_;
        stage.perStageLimit = perStageLimit_;
        emit StageUpdated(stageId_, mintingEnabled_, ethPrice_, tokenAmountLimit_, perClaimLimit_, perStageLimit_);
    }

    function _setPaymentConfig(address[] memory paymentRecipients_, uint256[] memory paymentPercents_) internal virtual {
        require(paymentRecipients_.length == paymentPercents_.length, "SwapERC721Ambrose: arrays length mismatch");
        uint256 totalPercent = 0;
        for (uint256 i = 0; i < paymentRecipients_.length; ++i) {
            require(paymentRecipients_[i] != address(0), "SwapERC721Ambrose: invalid address");
            totalPercent += paymentPercents_[i];
        }
        require(totalPercent == _100_PERCENT, "SwapERC721Ambrose: invalid total percent");
        _paymentRecipients = paymentRecipients_;
        _paymentPercents = paymentPercents_;
        emit PaymentConfigUpdated(paymentRecipients_, paymentPercents_);
    }

    function _claimToken(address account_, uint256 stageId_, uint256 tokenAmount_, uint256 ethAmount_) internal virtual {
        // check before claim and check eth amount
        uint256 expectedEthAmount = checkBeforeClaim(account_, stageId_, tokenAmount_);
        require((ethAmount_ == expectedEthAmount) && (ethAmount_ == msg.value), "SwapERC721Ambrose: invalid ETH amount");
        // update stage params
        StageData storage stage = _stages[stageId_];
        stage.ethAmount += ethAmount_;
        stage.tokenAmount += tokenAmount_;
        // update claimed tokens params
        _claimedTokens[account_][stageId_] += tokenAmount_;
        // send eth to recipients
        _sendPaymentsToRecipients(ethAmount_);
        // mint erc721 tokens
        IERC721AmbroseUpgradeable(_erc721AmbroseAddress).mintTokenBatch(account_, tokenAmount_);
        emit TokenClaimed(account_, stageId_, tokenAmount_, ethAmount_);
    }

    function _sendPaymentsToRecipients(uint256 ethAmount_) internal virtual {
        uint256[] memory paymentEthAmounts = new uint256[](_paymentRecipients.length);
        for (uint256 i = 0; i < _paymentRecipients.length; ++i) {
            paymentEthAmounts[i] = ethAmount_ * _paymentPercents[i] / _100_PERCENT;
            AddressUpgradeable.sendValue(payable(_paymentRecipients[i]), paymentEthAmounts[i]);
        }
        emit PaymentsSentToRecipients(_paymentRecipients, paymentEthAmounts);
    }
}