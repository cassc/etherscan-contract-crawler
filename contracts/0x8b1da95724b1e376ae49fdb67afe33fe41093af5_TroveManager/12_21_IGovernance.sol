// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IPriceFeed.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IOracle.sol";

interface IGovernance {
    event AllowMintingChanged(bool oldFlag, bool newFlag, uint256 timestamp);
    event BorrowingFeeFloorChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event FundAddressChanged(address oldAddress, address newAddress, uint256 timestamp);
    event MaxBorrowingFeeChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event MAHAChanged(address oldAddress, address newAddress, uint256 timestamp);
    event MaxDebtCeilingChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event PriceFeedChanged(address oldAddress, address newAddress, uint256 timestamp);
    event RedemptionFeeFloorChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event SentToFund(address token, uint256 amount, uint256 timestamp, string reason);

    function getAllowMinting() external view returns (bool);

    function getBorrowingFeeFloor() external view returns (uint256);

    function getDeploymentStartTime() external view returns (uint256);

    function getFund() external view returns (address);

    function getMAHA() external view returns (IERC20);

    function getGasCompensation() external view returns (uint256);

    function getMaxBorrowingFee() external view returns (uint256);

    function getMaxDebtCeiling() external view returns (uint256);

    function getMinNetDebt() external view returns (uint256);

    function getPriceFeed() external view returns (IPriceFeed);

    function getRedemptionFeeFloor() external view returns (uint256);
}