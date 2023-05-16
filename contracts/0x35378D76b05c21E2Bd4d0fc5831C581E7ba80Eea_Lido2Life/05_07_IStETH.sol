// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStETH is IERC20 {
    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);
}