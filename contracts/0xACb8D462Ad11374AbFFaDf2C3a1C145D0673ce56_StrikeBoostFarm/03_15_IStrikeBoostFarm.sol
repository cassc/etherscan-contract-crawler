// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IStrikeBoostFarm {
    function move(uint256 pid, address sender, address recipient, uint256 amount) external;
}