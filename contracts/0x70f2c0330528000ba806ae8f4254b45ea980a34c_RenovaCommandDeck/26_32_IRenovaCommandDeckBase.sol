// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import './IRenovaQuest.sol';

/// @title IRenovaCommandDeckBase
/// @author Victor Ionescu
/**

The Command Deck contract is a central point of command in the Hashverse.
It handles:
- official contract addresses for the Item and the Avatar
- minting of Hashverse Items post Quest completion
- creation of Quests

The Command Deck exists on every chain, however only the main chain
Command Deck can mint items.
*/
interface IRenovaCommandDeckBase {
    /// @notice Emitted every time the Hashflow Router is updated.
    /// @param newRouter The address of the new Hashflow Router.
    /// @param oldRouter The address of the old Hashflow Router.
    event UpdateHashflowRouter(address newRouter, address oldRouter);

    /// @notice Emitted every time the Quest Owner changes.
    /// @param newQuestOwner The address of the new Quest Owner.
    /// @param oldQuestOwner The address of the old Quest Owner.
    event UpdateQuestOwner(address newQuestOwner, address oldQuestOwner);

    /// @notice Emitted every time a Quest is created.
    /// @param questId The Quest ID.
    /// @param questAddress The address of the contract handling the Quest logic.
    /// @param startTime The quest start time, in unix seconds.
    /// @param endTime The quest end time, in unix seconds.
    /// @param depositToken The token to be deposited to enter.
    /// @param minDepositAmount The minimum ampount to be deposited to enter.
    event CreateQuest(
        bytes32 questId,
        address questAddress,
        uint256 startTime,
        uint256 endTime,
        address depositToken,
        uint256 minDepositAmount
    );

    /// @notice Returns the Avatar contract address.
    /// @return The address of the Avatar contract.
    function renovaAvatar() external view returns (address);

    /// @notice Returns the Item contract address.
    /// @return The address of the Item contract.
    function renovaItem() external view returns (address);

    /// @notice Returns the Router contract address.
    /// @return The address of the Router contract.
    function hashflowRouter() external view returns (address);

    /// @notice Returns the Quest Owner address.
    /// @return The address of the Quest Owner.
    function questOwner() external view returns (address);

    /// @notice Returns the deployment contract address for a quest ID.
    /// @param questId The Quest ID.
    /// @return The deployed contract address if the quest ID is valid.
    function questDeploymentAddresses(
        bytes32 questId
    ) external view returns (address);

    /// @notice Returns the ID of a quest deployed at a particular address.
    /// @param questAddress The address of the Quest contract.
    /// @return The quest ID.
    function questIdsByDeploymentAddress(
        address questAddress
    ) external view returns (bytes32);

    /// @notice Deposits tokens into a Quest.
    /// @param player The address of the player depositing the tokens.
    /// @param depositAmount The deposit amount.
    /// @dev This function helps save gas by only setting allowance to this contract.
    function depositTokenForQuest(
        address player,
        uint256 depositAmount
    ) external;

    /// @notice Creates a Quest in the Hashverse.
    /// @param questId The Quest ID.
    /// @param startTime The quest start time, in Unix seconds.
    /// @param endTime The quest end time, in Unix seconds.
    /// @param depositToken The token that needs to be deposited in order for a player to enter.
    /// @param minDepositAmount The min amount deposited.
    function createQuest(
        bytes32 questId,
        uint256 startTime,
        uint256 endTime,
        address depositToken,
        uint256 minDepositAmount
    ) external;

    /// @notice Updates the Hashflow Router contract address.
    /// @param hashflowRouter The new Hashflow Router contract address.
    function updateHashflowRouter(address hashflowRouter) external;

    /// @notice Updates the Quest Owner address.
    /// @param questOwner The new Quest Owner address.
    function updateQuestOwner(address questOwner) external;
}