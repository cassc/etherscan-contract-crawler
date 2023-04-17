// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IArrakisV2Beacon} from "./IArrakisV2Beacon.sol";
import {InitializePayload} from "../structs/SArrakisV2.sol";

interface IArrakisV2Factory {
    event VaultCreated(address indexed manager, address indexed vault);

    event InitFactory(address owner);

    function deployVault(InitializePayload calldata params_, bool isBeacon_)
        external
        returns (address vault);

    function upgradeVaults(address[] memory vaults_) external;

    function upgradeVaultsAndCall(
        address[] memory vaults_,
        bytes[] calldata datas_
    ) external;

    function makeVaultsImmutable(address[] memory vaults_) external;

    // #region view functions

    function arrakisV2Beacon() external view returns (IArrakisV2Beacon);

    function numVaults() external view returns (uint256);

    function vaults(uint256 startIndex_, uint256 endIndex_)
        external
        view
        returns (address[] memory);

    function getProxyAdmin(address proxy) external view returns (address);

    function getProxyImplementation(address proxy)
        external
        view
        returns (address);

    function getTokenName(address token0_, address token1_)
        external
        view
        returns (string memory);

    // #endregion view functions
}