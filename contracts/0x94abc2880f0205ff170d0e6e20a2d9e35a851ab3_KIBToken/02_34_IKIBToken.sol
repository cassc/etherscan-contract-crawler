// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IERC20PermitUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20PermitUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20MetadataUpgradeable.sol";
import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";
import {IMCAGRateFeed} from "./IMCAGRateFeed.sol";

interface IKIBToken is IERC20MetadataUpgradeable, IERC20PermitUpgradeable {
    event CumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);
    event EpochLengthSet(uint256 previousEpochLength, uint256 newEpochLength);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event MinEpochLengthSet(uint256 previousMinEpochLength, uint256 newMinEpochLength);
    event PreviousEpochCumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);
    event RiskCategorySet(bytes32 riskCategory);
    event YieldUpdated(uint256 oldYield, uint256 newYield);

    function initialize(
        string memory name,
        string memory symbol,
        uint256 epochLength,
        IKUMAAddressProvider KUMAAddressProvider,
        bytes4 currency,
        bytes32 issuer,
        uint32 term
    ) external;

    function setEpochLength(uint256 epochLength) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function setMinEpochLength(uint96 minEpochLength) external;

    function refreshYield() external;

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider);

    function getMinEpochLength() external view returns (uint256);

    function getRiskCategory() external view returns (bytes32);

    function getYield() external view returns (uint256);

    function getTotalBaseSupply() external view returns (uint256);

    function getBaseBalance(address account) external view returns (uint256);

    function getEpochLength() external view returns (uint256);

    function getLastRefresh() external view returns (uint256);

    function getCumulativeYield() external view returns (uint256);

    function getUpdatedCumulativeYield() external view returns (uint256);

    function getPreviousEpochTimestamp() external view returns (uint256);
}