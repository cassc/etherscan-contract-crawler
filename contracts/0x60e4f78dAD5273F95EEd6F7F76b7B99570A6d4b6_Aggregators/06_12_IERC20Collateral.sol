// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Collateral is IERC20{
    function decimals() external view returns (uint8);
}