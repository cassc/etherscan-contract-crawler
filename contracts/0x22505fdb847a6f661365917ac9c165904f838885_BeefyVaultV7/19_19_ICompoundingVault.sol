//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICompoundingVault {
    function deposit(uint amount) external returns (uint256);

    function withdraw(uint amount) external returns (uint256);

    function want() external view returns (IERC20Upgradeable);
}