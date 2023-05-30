// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IKOAccessControlsLookup} from "./interfaces/IKOAccessControlsLookup.sol";
import {IKODASettings} from "./interfaces/IKODASettings.sol";
import {ZeroAddress} from "./errors/KODAErrors.sol";
import {Konstants} from "./Konstants.sol";

/// @title KnownOrigin Generalised Marketplace Settings For KODA Version 4 and beyond
/// @notice KODASettings grants flexibility in commission collected at primary and secondary point of sale
contract KODASettings is UUPSUpgradeable, Konstants, IKODASettings {
    /// @notice Address of the contract that defines who can update settings
    IKOAccessControlsLookup public accessControls;

    /// @notice Fee applied to all primary sales
    uint256 public platformPrimaryCommission;

    /// @notice Fee applied to all secondary sales
    uint256 public platformSecondaryCommission;

    /// @notice Address of the platform handler
    address public platform;

    /// @notice Base KO API endpoint
    string public baseKOApi;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _platform,
        string calldata _baseKOApi,
        IKOAccessControlsLookup _accessControls
    ) external initializer {
        if (_platform == address(0)) revert ZeroAddress();
        if (address(_accessControls) == address(0)) revert ZeroAddress();

        __UUPSUpgradeable_init();

        platformPrimaryCommission = 15_00000;
        platformSecondaryCommission = 2_50000;

        platform = _platform;
        baseKOApi = _baseKOApi;
        accessControls = _accessControls;
    }

    /// @dev Only admins can trigger smart contract upgrades
    function _authorizeUpgrade(address) internal view override {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
    }

    /// @notice Admin update for primary sale platform percentage for V4 or newer KODA contracts when sold within platform
    /// @dev It is possible to set this value to zero
    function updatePlatformPrimaryCommission(uint256 _percentage) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_percentage > MAX_PLATFORM_COMMISSION)
            revert MaxCommissionExceeded();
        platformPrimaryCommission = _percentage;
        emit PlatformPrimaryCommissionUpdated(_percentage);
    }

    /// @notice Admin update for secondary sale platform percentage for V4 or newer KODA contracts when sold within platform
    /// @dev It is possible to set this value to zero
    function updatePlatformSecondaryCommission(uint256 _percentage) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_percentage > MAX_PLATFORM_COMMISSION)
            revert MaxCommissionExceeded();
        platformSecondaryCommission = _percentage;
        emit PlatformSecondaryCommissionUpdated(_percentage);
    }

    /// @notice Admin can update the address that will receive proceeds from primary and secondary sales
    function setPlatform(address _platform) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        if (_platform == address(0)) revert ZeroAddress();
        platform = _platform;
        emit PlatformUpdated(_platform);
    }

    /// @notice Admin can update the base KO API
    function setBaseKOApi(string calldata _baseKOApi) external {
        if (!accessControls.hasAdminRole(msg.sender)) revert OnlyAdmin();
        baseKOApi = _baseKOApi;
        emit BaseKOAPIUpdated(_baseKOApi);
    }
}