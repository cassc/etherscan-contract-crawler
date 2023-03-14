// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStaking.sol";

interface ITokenStaking is IStaking {

    function getErc20Token() external view returns (IERC20);

    function distributeRewards(address validatorAddress, uint256 amount) external;
}