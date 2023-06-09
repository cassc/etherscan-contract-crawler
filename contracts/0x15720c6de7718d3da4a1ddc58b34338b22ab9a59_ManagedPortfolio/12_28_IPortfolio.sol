// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20Upgradeable} from "IERC20Upgradeable.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";

interface IPortfolio is IERC20Upgradeable {
    function endDate() external view returns (uint256);

    function underlyingToken() external view returns (IERC20WithDecimals);

    function value() external view returns (uint256);

    function deposit(uint256 amount, bytes memory metadata) external;

    function withdraw(uint256 amount, bytes memory metadata) external returns (uint256 withdrawnAmount);
}