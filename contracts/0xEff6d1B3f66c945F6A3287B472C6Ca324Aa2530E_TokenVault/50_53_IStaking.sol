// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IStaking is IERC20Upgradeable {
    //
    function delegate(address delegatee) external;

    function getStakingTotal() external view returns (uint256);

    function changingBalance() external view returns (uint256);

    function addRewardToken(address _addr) external;

    function deposit(uint256 amount, uint256 poolId) external;

    function withdraw(uint256 sId, uint256 amount) external;

    function convertFTokenToVeToken(uint256 amount) external;

    function redeemFToken(uint256 amount) external;
}