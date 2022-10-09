// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITokenForLiquidityManager is IERC20Upgradeable {
    function approveForLiquidityManger(address liquidityPair, uint256 amount)
        external;
}