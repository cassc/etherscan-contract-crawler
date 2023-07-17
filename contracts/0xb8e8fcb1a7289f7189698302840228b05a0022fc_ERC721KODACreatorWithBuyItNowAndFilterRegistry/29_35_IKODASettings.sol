// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IKOAccessControlsLookup} from "./IKOAccessControlsLookup.sol";

interface IKODASettings {
    error MaxCommissionExceeded();
    error OnlyAdmin();
    event PlatformPrimaryCommissionUpdated(uint256 _percentage);
    event PlatformSecondaryCommissionUpdated(uint256 _percentage);
    event PlatformUpdated(address indexed _platform);
    event BaseKOAPIUpdated(string _baseKOApi);

    function initialize(
        address _platform,
        string calldata _baseKOApi,
        IKOAccessControlsLookup _accessControls
    ) external;

    /// @notice Admin update for primary sale platform percentage for V4 or newer KODA contracts when sold within platform
    function updatePlatformPrimaryCommission(uint256 _percentage) external;

    /// @notice Admin update for secondary sale platform percentage for V4 or newer KODA contracts when sold within platform
    function updatePlatformSecondaryCommission(uint256 _percentage) external;

    /// @notice Admin can update the address that will receive proceeds from primary and secondary sales
    function setPlatform(address _platform) external;

    /// @notice Admin can update the base KO API
    function setBaseKOApi(string calldata _baseKOApi) external;
}