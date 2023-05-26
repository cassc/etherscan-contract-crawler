// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import { IERC20 as ERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface WSTRInterface {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract WSTR is WSTRInterface {}