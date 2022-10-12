// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2Beacon} from "./IArrakisV2Beacon.sol";
import {InitializePayload} from "./IArrakisV2.sol";

interface IArrakisV2Factory {
    event VaultCreated(address indexed manager, address indexed vault);

    event InitFactory(address owner);

    function deployVault(InitializePayload calldata params_, bool isBeacon_)
        external
        returns (address vault);

    // #region view functions

    function version() external view returns (string memory);

    function arrakisV2Beacon() external view returns (IArrakisV2Beacon);

    function numVaults() external view returns (uint256);

    function vaults() external view returns (address[] memory);

    function getProxyAdmin(address proxy) external view returns (address);

    function getProxyImplementation(address proxy)
        external
        view
        returns (address);

    // #endregion view functions
}