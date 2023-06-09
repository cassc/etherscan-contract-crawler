// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "lib/mcag-contracts/src/interfaces/MCAGAggregatorInterface.sol";

interface IMCAGRateFeed {
    event AccessControllerSet(address accessController);
    event OracleSet(address oracle, bytes4 indexed currency, bytes32 indexed issuer, uint64 indexed term);
    event StalenessThresholdSet(uint256 stalenessThreshold);

    function initialize(IAccessControl accessController, uint256 stalenessThreshold) external;

    function setOracle(bytes4 currency, bytes32 issuer, uint32 term, MCAGAggregatorInterface oracle) external;

    function setStalenessThreshold(uint256 stalenessThreshold) external;

    function minRateCoupon() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getAccessController() external view returns (IAccessControl);

    function getRate(bytes32 riskCategory) external view returns (uint256);

    function getOracle(bytes32 riskCategory) external view returns (MCAGAggregatorInterface);

    function getStalenessThreshold() external view returns (uint256);
}