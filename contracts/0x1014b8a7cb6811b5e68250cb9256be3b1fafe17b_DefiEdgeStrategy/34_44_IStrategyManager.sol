//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "./IStrategyFactory.sol";

interface IStrategyManager {
    function isUserWhiteListed(address _account) external view returns (bool);

    function isAllowedToManage(address) external view returns (bool);

    function isAllowedToBurn(address) external view returns (bool);

    function managementFeeRate() external view returns (uint256); // 1e8 decimals

    function performanceFeeRate() external view returns (uint256); // 1e8 decimals

    function operator() external view returns (address);

    function limit() external view returns (uint256);

    function allowedDeviation() external view returns (uint256); // 1e18 decimals

    function allowedSwapDeviation() external view returns (uint256); // 1e18 decimals

    function feeTo() external view returns (address);

    function factory() external view returns (IStrategyFactory);

    function increamentSwapCounter() external;
}