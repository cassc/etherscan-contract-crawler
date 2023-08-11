// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IStablecoinYieldConnector
 * @author Souq.Finance
 * @notice Defines the interface of the stablecoin yield connector
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
 */
interface IStablecoinYieldConnector {
    event DepositUSDC(address indexed depositor, uint256 amount);
    event WithdrawUSDC(address indexed withdrawer, uint256 amount);
    event SetUSDCPool(address indexed setter, address poolAddress);
    event ChangeCollateral(address indexed setter, address reserve, bool useAsCollateral);

    function pause() external;

    function unpause() external;

    function getVersion() external pure returns (uint256);

    function getATokenAddress() external returns (address);

    function depositUSDC(uint256 amount) external;

    function withdrawUSDC(uint256 amount, uint256 aAmount) external;

    function setUSDCPool(address poolAddress) external;

    function getBalance() external view returns (uint256);

    function getReserveConfigurationData(
        address _reserve
    ) external view returns (uint256, uint256, uint256, uint256, uint256, bool, bool, bool, bool, bool);
}