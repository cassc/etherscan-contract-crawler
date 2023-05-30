// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOldVault is IERC20 {
    function withdrawETH(uint256 _share, uint256 minEth) external;
}