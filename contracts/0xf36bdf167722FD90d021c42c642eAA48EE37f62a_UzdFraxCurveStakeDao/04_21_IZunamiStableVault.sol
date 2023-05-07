//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./IStrategy.sol";

interface IZunamiStableVault is IERC20 {
    function deposit(uint256 nominal, address receiver) external returns (uint256);

    function withdraw(
        uint256 value,
        address receiver,
        address owner
    ) external returns (uint256);
}