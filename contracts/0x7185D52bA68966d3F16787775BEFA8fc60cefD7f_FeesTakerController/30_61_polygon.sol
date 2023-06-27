// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title RootChain Manager Interface for Polygon Bridge.
 */
interface IRootChainManager {
    /**
     * @notice Move ether from root to child chain, accepts ether transfer
     * Keep in mind this ether cannot be used to pay gas on child chain
     * Use Matic tokens deposited using plasma mechanism for that
     * @param user address of account that should receive WETH on child chain
     */
    function depositEtherFor(address user) external payable;

    /**
     * @notice Move tokens from root to child chain
     * @dev This mechanism supports arbitrary tokens as long as its predicate has been registered and the token is mapped
     * @param sender address of account that should receive this deposit on child chain
     * @param token address of token that is being deposited
     * @param extraData bytes data that is sent to predicate and child token contracts to handle deposit
     */
    function depositFor(
        address sender,
        address token,
        bytes memory extraData
    ) external;
}