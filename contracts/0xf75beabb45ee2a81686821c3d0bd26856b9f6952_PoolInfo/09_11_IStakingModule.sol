/*
IStakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";
import "./IOwnerController.sol";

/**
 * @title Staking module interface
 *
 * @notice this contract defines the common interface that any staking module
 * must implement to be compatible with the modular Pool architecture.
 */
interface IStakingModule is IOwnerController, IEvents {
    /**
     * @return array of staking tokens
     */
    function tokens() external view returns (address[] memory);

    /**
     * @notice get balance of user
     * @param user address of user
     * @return balances of each staking token
     */
    function balances(address user) external view returns (uint256[] memory);

    /**
     * @return address of module factory
     */
    function factory() external view returns (address);

    /**
     * @notice get total staked amount
     * @return totals for each staking token
     */
    function totals() external view returns (uint256[] memory);

    /**
     * @notice stake an amount of tokens for user
     * @param sender address of sender
     * @param amount number of tokens to stake
     * @param data additional data
     * @return bytes32 id of staking account
     * @return number of shares minted for stake
     */
    function stake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, uint256);

    /**
     * @notice unstake an amount of tokens for user
     * @param sender address of sender
     * @param amount number of tokens to unstake
     * @param data additional data
     * @return bytes32 id of staking account
     * @return address of reward receiver
     * @return number of shares burned for unstake
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, address, uint256);

    /**
     * @notice quote the share value for an amount of tokens without unstaking
     * @param sender address of sender
     * @param amount number of tokens to claim with
     * @param data additional data
     * @return bytes32 id of staking account
     * @return address of reward receiver
     * @return number of shares that the claim amount is worth
     */
    function claim(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, address, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @dev will only be called ad hoc and should not contain essential logic
     * @param sender address of user for update
     * @param data additional data
     * @return bytes32 id of staking account
     */
    function update(
        address sender,
        bytes calldata data
    ) external returns (bytes32);

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     * @param data additional data
     */
    function clean(bytes calldata data) external;
}