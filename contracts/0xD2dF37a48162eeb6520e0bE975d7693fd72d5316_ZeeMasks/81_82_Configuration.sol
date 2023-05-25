// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../../../acl/access-controlled/AccessControlledUpgradeable.sol";
import "../../../common/BlockAware.sol";
import "./IConfiguration.sol";

contract Configuration is IConfiguration, UUPSUpgradeable, AccessControlledUpgradeable, BlockAware {
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    BitMapsUpgradeable.BitMap internal _features;

    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    function initialize(address acl) external initializer {
        // solhint-disable-previous-line comprehensive-interface
        __BlockAware_init();
        __UUPSUpgradeable_init();
        __AccessControlled_init(acl);
    }

    /// @inheritdoc IConfiguration
    function setFeature(uint8 feature, bool value) external override onlyRole(Roles.AUXILIARY_CONTRACTS) {
        _features.setTo(feature, value);

        emit FeatureChanged(feature, value);
    }

    /// @inheritdoc IConfiguration
    function getFeature(uint8 feature) external view override returns (bool) {
        return _featureIsEnabled(feature);
    }

    /// @inheritdoc IConfiguration
    function getFeatures() external view override returns (uint256) {
        return _features._data[0];
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _featureIsEnabled(uint8 feature) internal view returns (bool) {
        return _features.get(feature);
    }
}