// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./IERC721BeduDffUpgradeable.sol";

contract SwapERC721BeduDffUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // Swap bedu dff contract address
    address private _erc721BeduDffAddress;
    // Swap trusted signer address
    address private _trustedSignerAddress;

    // Swap stage params
    uint256 private constant _MAX_PER_USER_LIMIT = 1;
    struct StageData {
        bool mintingEnabled;
        uint256 ethPrice;
        uint256 ethAmount;
        uint256 tokenAmount;
    }
    mapping(uint256 => StageData) private _stages;
    uint256 private _currentStageId;

    // Mapping from user claimed tokens
    mapping(uint256 => uint256) private _userClaimedTokens;

    // Emitted when `trustedSignerAddress` updated
    event TrustedSignerAddressUpdated(address trustedSignerAddress);

    // Emitted when new Stage updated
    event StageUpdated(uint256 stageId, bool mintingEnabled, uint256 ethPrice);
    // Emitted when current stageId updated
    event CurrentStageUpdated(uint256 stageId);

    // Emitted when `userId` receive tokens
    event TokenClaimed(uint256 indexed userId, address indexed account, uint256 stageId, uint256 tokenAmount, uint256 ethAmount);

    // Emitted when `ethAmount` withdrawn to `account`
    event EthWithdrawn(address account, uint256 ethAmount);

    function initialize(
        address erc721BeduDffAddress_,
        address trustedSignerAddress_
    ) public virtual initializer {
        __SwapERC721BeduDff_init(
            erc721BeduDffAddress_,
            trustedSignerAddress_
        );
    }

    function __SwapERC721BeduDff_init(
        address erc721BeduDffAddress_,
        address trustedSignerAddress_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapERC721BeduDff_init_unchained(
            erc721BeduDffAddress_,
            trustedSignerAddress_
        );
    }

    function __SwapERC721BeduDff_init_unchained(
        address erc721BeduDffAddress_,
        address trustedSignerAddress_
    ) internal initializer {
        require(erc721BeduDffAddress_ != address(0), "SwapERC721BeduDff: invalid address");
        require(trustedSignerAddress_ != address(0), "SwapERC721BeduDff: invalid address");
        _erc721BeduDffAddress = erc721BeduDffAddress_;
        _trustedSignerAddress = trustedSignerAddress_;
    }

    function erc721BeduDffAddress() external view virtual returns (address) {
        return _erc721BeduDffAddress;
    }

    function trustedSignerAddress() external view virtual returns (address) {
        return _trustedSignerAddress;
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
            uint256 tokenAmount
        )
    {
        StageData storage stage = _stages[stageId_];
        return (
            stage.mintingEnabled,
            stage.ethPrice,
            stage.ethAmount,
            stage.tokenAmount
        );
    }

    function userClaimedTokens(uint256 userId_) external view virtual returns (uint256) {
        return _userClaimedTokens[userId_];
    }

    function checkBeforeClaim(uint256 userId_, address account_, uint256 stageId_, uint256 tokenAmount_) public view virtual returns (uint256 ethAmount) {
        // validate params
        require(userId_ != 0, "SwapERC721BeduDff: invalid userId");
        require(account_ != address(0), "SwapERC721BeduDff: invalid address");
        require(stageId_ == _currentStageId, "SwapERC721BeduDff: invalid stageId");
        require(tokenAmount_ != 0 && (_userClaimedTokens[userId_] + tokenAmount_) <= _MAX_PER_USER_LIMIT, "SwapERC721BeduDff: invalid token amount");
        // check contracts params
        require(!paused(), "SwapERC721BeduDff: contract is paused");
        require(!IERC721BeduDffUpgradeable(_erc721BeduDffAddress).paused(), "SwapERC721BeduDff: erc721 is paused");
        require(IERC721BeduDffUpgradeable(_erc721BeduDffAddress).isTrustedMinter(address(this)), "SwapERC721BeduDff: erc721 wrong trusted minter");
        // check stage params
        StageData storage stage = _stages[stageId_];
        require(stage.mintingEnabled, "SwapERC721BeduDff: stage minting disabled");
        // calculate eth amount
        return stage.ethPrice * tokenAmount_;
    }

    function claimToken(
        uint256 userId_,
        uint256 stageId_,
        uint256 tokenAmount_,
        uint256 ethAmount_,
        uint256 nonce_,
        uint256 salt_,
        uint256 maxBlockNumber_,
        bytes memory signature_
    ) external virtual payable nonReentrant whenNotPaused {
        // check signature
        bytes32 hash = keccak256(abi.encodePacked(userId_, _msgSender(), stageId_, tokenAmount_, ethAmount_, nonce_, salt_, maxBlockNumber_));
        address signer = hash.toEthSignedMessageHash().recover(signature_);
        require(signer == _trustedSignerAddress, "SwapERC721BeduDff: invalid signature");
        // check max block limit
        require(block.number <= maxBlockNumber_, "SwapERC721BeduDff: failed max block check");
        // claim tokens
        _claimToken(userId_, _msgSender(), stageId_, tokenAmount_, ethAmount_);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateTrustedSignerAddress(address trustedSignerAddress_) external virtual onlyOwner {
        require(trustedSignerAddress_ != address(0), "SwapERC721BeduDff: invalid address");
        _trustedSignerAddress = trustedSignerAddress_;
        emit TrustedSignerAddressUpdated(trustedSignerAddress_);
    }

    function updateCurrentStageId(uint256 stageId_) external virtual onlyOwner {
        _currentStageId = stageId_;
        emit CurrentStageUpdated(stageId_);
    }

    function updateStage(uint256 stageId_, bool mintingEnabled_, uint256 ethPrice_) external virtual onlyOwner {
        require(stageId_ != 0, "SwapERC721BeduDff: invalid stageId");
        StageData storage stage = _stages[stageId_];
        stage.mintingEnabled = mintingEnabled_;
        stage.ethPrice = ethPrice_;
        emit StageUpdated(stageId_, mintingEnabled_, ethPrice_);
    }

    function withdrawEth(address payable account_, uint256 ethAmount_) external virtual onlyOwner {
        require(account_ != address(0), "SwapERC721BeduDff: invalid address");
        require(ethAmount_ != 0, "SwapERC721BeduDff: invalid amount");
        AddressUpgradeable.sendValue(account_, ethAmount_);
        emit EthWithdrawn(account_, ethAmount_);
    }

    function _claimToken(uint256 userId_, address account_, uint256 stageId_, uint256 tokenAmount_, uint256 ethAmount_) internal virtual {
        // check before claim and check eth amount
        uint256 expectedEthAmount = checkBeforeClaim(userId_, account_, stageId_, tokenAmount_);
        require((ethAmount_ == expectedEthAmount) && (ethAmount_ == msg.value), "SwapERC721BeduDff: invalid ETH amount");
        // update user claimed tokens
        _userClaimedTokens[userId_] += tokenAmount_;
        // update stage params
        StageData storage stage = _stages[stageId_];
        stage.ethAmount += ethAmount_;
        stage.tokenAmount += tokenAmount_;
        // mint erc721 tokens
        IERC721BeduDffUpgradeable(_erc721BeduDffAddress).mintTokenBatch(account_, tokenAmount_);
        emit TokenClaimed(userId_, account_, stageId_, tokenAmount_, ethAmount_);
    }
}