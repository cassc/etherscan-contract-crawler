// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "../../../acl/access-controlled/AccessControlledUpgradeable.sol";
import "../configuration/ConfigurationControlled.sol";
import "../whitelist/IWhitelistManager.sol";
import "../tiers/ITierPricingManager.sol";
import "../../../common/BlockAware.sol";
import "../configuration/Features.sol";
import "./ISaleManager.sol";
import "../../IZeeNFT.sol";

contract SaleManager is
    ISaleManager,
    UUPSUpgradeable,
    ConfigurationControlled,
    AccessControlledUpgradeable,
    BlockAware
{
    // TODO move state variables to a storage contract
    address internal _vault;
    IZeeNFT internal _zeeNFT;
    IWhitelistManager internal _whitelistManager;
    ITierPricingManager internal _tierManager;
    uint64 internal _tokensBoughtViaPublicMint;
    mapping(address => uint256) internal _tokensBoughtViaPublicMintPerUser;

    modifier saleIsActive() {
        ITierPricingManager.Tier memory tier = _tierManager.getLastTier();
        if (_tokensBoughtViaPublicMint >= tier.threshold) revert MintingLimitReached();
        _;
    }

    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    // solhint-disable-next-line comprehensive-interface
    function initialize(
        address configuration,
        address acl,
        address whitelistManager,
        address tierManager,
        address zeeNft,
        address vault
    ) external initializer {
        // TODO: check that the whitelist manager is actually a whitelist manager
        // TODO: check that the tier manager is actually a tier manager
        // TODO: check that the zeeNft is actually a zeeNft

        __BlockAware_init();
        __ConfigurationControlled_init(configuration);
        __AccessControlled_init(acl);
        _vault = vault;
        _zeeNFT = IZeeNFT(zeeNft);
        _whitelistManager = IWhitelistManager(whitelistManager);
        _tierManager = ITierPricingManager(tierManager);
    }

    /// @inheritdoc ISaleManager
    receive() external payable override {
        // solhint-disable-previous-line ordering
        bytes32[] memory proof = new bytes32[](0);

        (ITierPricingManager.Tier memory tier, uint256 tierIndex, uint256 totalTiers) = _tierManager.getCurrentTier();
        uint256 price = tier.price;
        if (msg.value < price || msg.value % price != 0) revert InvalidFundsSent();

        uint256 count = msg.value / price;
        _transferAndMint(proof, uint64(count), tier, tierIndex, totalTiers);
    }

    function buy(bytes32[] calldata whitelistProof, uint64 count) external payable override {
        (ITierPricingManager.Tier memory tier, uint256 tierIndex, uint256 totalTiers) = _tierManager.getCurrentTier();
        _transferAndMint(whitelistProof, count, tier, tierIndex, totalTiers);
    }

    /// @notice transfer ETH to the vault account, mint a new token
    /// @dev will revert if current purchase count exceeds the current tier
    /// @dev will revert if ETH amount is not exactly equal to the token price
    /// @dev will revert if the user has reached his personal mint limit
    /// @dev will revert if the public token sale limit has been reached
    /// @dev manages the public sale token tracker
    // solhint-disable-next-line code-complexity
    function _transferAndMint(
        bytes32[] memory whitelistProof,
        uint64 count,
        ITierPricingManager.Tier memory tier,
        uint256 currentTierIndex,
        uint256 totalTiers
    ) internal whenEnabled(Features._MINTING) saleIsActive {
        if (!_whitelistManager.isUserWhitelisted(msg.sender, whitelistProof)) revert NotWhitelisted();

        uint64 newPublicMintCount = _tokensBoughtViaPublicMint + count;
        if (count == 0) revert CannotPurchaseZeroTokens();
        if (newPublicMintCount > tier.threshold) revert PurchaseExceedsCurrentTier();
        if (tier.capPerUser <= _tokensBoughtViaPublicMintPerUser[msg.sender]) revert UserPurchasingCapReached();
        if (msg.value != (tier.price * count)) revert InsufficientFunds();

        // Shift the tier index
        if (
            // Only if the currently minted tokens exceed the current threshold
            (newPublicMintCount >= tier.threshold) &&
            // Only if it is not the very last threshold
            (currentTierIndex < totalTiers - 1)
        ) {
            _tierManager.bumpTier();
        }

        // Buy tokens
        _tokensBoughtViaPublicMint = newPublicMintCount;
        _tokensBoughtViaPublicMintPerUser[msg.sender] += count;

        // Mint the actual tokens
        _zeeNFT.mint(msg.sender, count);

        AddressUpgradeable.sendValue(payable(_vault), msg.value);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }
}