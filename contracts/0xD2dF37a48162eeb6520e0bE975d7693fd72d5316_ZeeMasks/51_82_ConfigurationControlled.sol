// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IConfiguration.sol";

abstract contract ConfigurationControlled is Initializable {
    error FeatureEnabled(uint8 feature);
    error FeatureDisabled(uint8 feature);

    bytes32 private constant _CONFIGURATION_SLOT = bytes32(uint256(keccak256("zee-game.configuration.slot")) - 1);

    modifier whenEnabled(uint8 feature) {
        if (!_getFeature(feature)) revert FeatureDisabled(feature);
        _;
    }

    modifier whenDisabled(uint8 feature) {
        if (_getFeature(feature)) revert FeatureEnabled(feature);
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ConfigurationControlled_init(address configuration) internal onlyInitializing {
        // TODO interface check
        StorageSlot.getAddressSlot(_CONFIGURATION_SLOT).value = configuration;
    }

    function _enableFeature(uint8 feature) internal {
        return _getConfiguration().setFeature(feature, true);
    }

    function _disableFeature(uint8 feature) internal {
        return _getConfiguration().setFeature(feature, false);
    }

    function _getConfiguration() internal view returns (IConfiguration) {
        return IConfiguration(StorageSlot.getAddressSlot(_CONFIGURATION_SLOT).value);
    }

    function _getFeature(uint8 feature) internal view returns (bool) {
        return _getConfiguration().getFeature(feature);
    }
}