// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ITierPricingManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "../../../acl/access-controlled/AccessControlledUpgradeable.sol";
import "../configuration/ConfigurationControlled.sol";
import "../../../common/BlockAware.sol";
import "../configuration/Features.sol";

contract TierPricingManager is
    ITierPricingManager,
    UUPSUpgradeable,
    ConfigurationControlled,
    AccessControlledUpgradeable,
    BlockAware
{
    // TODO move storage variables to a storage contract
    uint256 internal _currentTierIndex;
    Tier[] internal _tiers;

    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    // solhint-disable-next-line comprehensive-interface
    function initialize(address configuration, address acl) external initializer {
        __BlockAware_init();
        __UUPSUpgradeable_init();
        __ConfigurationControlled_init(configuration);
        __AccessControlled_init(acl);
    }

    /// @inheritdoc ITierPricingManager
    function setTiers(Tier[] calldata tiers) external override onlyMaintainer whenEnabled(Features._CONFIGURING) {
        delete _tiers;
        if (tiers.length == 0) revert TierMustContainAtLeastOneEntry();

        // TODO can we use a do-while loop here?
        _checkValidCap(0, tiers[0]);
        _tiers.push(tiers[0]);

        for (uint256 i = 1; i < tiers.length; i++) {
            // Validate that each threshold is strictly larger to the previous
            if (tiers[i - 1].threshold >= tiers[i].threshold) revert InvalidTierThresholdSupplied(i);

            // Validate that each user-specific token cap is larger or equal to the previous
            if (tiers[i - 1].capPerUser > tiers[i].capPerUser) revert InvalidTierCapPerUser(i);

            _checkValidCap(i, tiers[i]);
            _tiers.push(tiers[i]);
        }

        uint64 publicMintTokenLimit = tiers[tiers.length - 1].threshold;

        emit TiersUpdated(tiers);
        emit CurrentTierSet(tiers[0]);
        emit PublicTokenLimitSet(publicMintTokenLimit);
    }

    /// @inheritdoc ITierPricingManager
    function bumpTier() external override {
        _currentTierIndex += 1;

        emit CurrentTierSet(_tiers[_currentTierIndex]);
    }

    /// @inheritdoc ITierPricingManager
    function getTiers() external view override returns (Tier[] memory tiers) {
        tiers = _tiers;
    }

    /// @inheritdoc ITierPricingManager
    function getCurrentTier()
        external
        view
        override
        returns (
            Tier memory currentTier,
            uint256 currentTierIndex,
            uint256 totalTiers
        )
    {
        currentTier = _tiers[_currentTierIndex];
        currentTierIndex = _currentTierIndex;
        totalTiers = _tiers.length;
    }

    /// @inheritdoc ITierPricingManager
    function getLastTier() external view override returns (Tier memory lastTier) {
        lastTier = _tiers[_tiers.length - 1];
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _checkValidCap(uint256 index, Tier memory tier) internal pure {
        if (tier.capPerUser > tier.threshold) revert TierCapLargerThanThreshold(index, tier.capPerUser, tier.threshold);
    }
}