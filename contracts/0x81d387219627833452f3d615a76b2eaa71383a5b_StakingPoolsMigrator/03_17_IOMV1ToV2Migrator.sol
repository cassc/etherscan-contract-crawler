// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IOMV1ToV2Migrator {
    function pool() external view returns (uint256);
    function v1Token() external view returns (IERC20);
    function v2Token() external view returns (IERC20);

    function increasePool(uint256 amount) external returns (bool success);
    function migrate(uint256 amount) external returns (bool success);
}