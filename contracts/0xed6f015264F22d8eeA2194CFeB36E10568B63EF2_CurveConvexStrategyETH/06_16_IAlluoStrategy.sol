// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAlluoStrategy {
    /// @notice Invest tokens transferred to this contract.
    /// @dev Amount of tokens specified in `amount` is guranteed to be
    /// transferred to strategy by vote executor.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param amount amount of your tokens that will be invested.
    /// @return data that MUST be passed in exiting functions
    function invest(bytes calldata data, uint256 amount)
        external
        returns (bytes memory);

    /// @notice Uninvest value and tranfer exchanged value to receiver.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param unwindPercent percentage of available assets to be released with 2 decimal points.
    /// @param outputCoin address of token that strategy MUST return.
    /// @param receiver address where tokens should go.
    /// @param swapRewards true if rewards are needed to swap to `outputCoin`, false otherwise.
    function exitAll(
        bytes calldata data,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external;

    /// @notice Claim available rewards.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param outputCoin address of token that strategy MUST return (if swapRewards is true).
    /// @param receiver address where tokens should go.
    /// @param swapRewards true if rewards are needed to swap to `outputCoin`, false otherwise.
    function exitOnlyRewards(
        bytes calldata data,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external;

    /// @notice Execute any action on behalf of strategy.
    /// @dev Regular call is executed. If any of extcall fails, transaction should revert.
    /// @param destinations addresses to call
    /// @param calldatas calldatas to execute
    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external;
}