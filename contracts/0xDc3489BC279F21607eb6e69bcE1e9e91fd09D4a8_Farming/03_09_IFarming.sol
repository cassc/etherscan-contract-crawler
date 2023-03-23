// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct Stack {
    uint256 count; // the stack size
    uint256 creationInterval; // creation or edit interval
}

interface IFarming {
    /// @dev account added stack count
    event OnAddStack(address indexed account, Stack stack, uint256 count);
    /// @dev account removed stack count
    event OnRemoveStack(address indexed account, Stack stack, uint256 count);
    /// @dev account claimed eth
    event OnClaimEth(address indexed account, Stack stack, uint256 count);
    /// @dev account claimed erc20
    event OnClaimErc20(address indexed account, Stack stack, uint256 count);
    /// @dev next interval
    event OnNextInterval(uint256 interval);

    /// @dev the intervals time length
    function timeIntervalLength() external view returns (uint256);

    /// @dev sets time interval number in hours
    /// onlyOwner
    function setTimeIntervalLengthHours(uint256 intervalHours) external;

    /// @dev current interval number
    function intervalNumber() external view returns (uint256);

    /// @dev time of next interval. Can be less then current time if if next interwal is already started, but no one write function has been at new interval
    function nextIntervalTime() external view returns (uint256);

    /// @dev next interval lapsed seconds or 0 if next interwal is already started, but no one write function has been at new interval
    function nextIntervalLapsedSeconds() external view returns (uint256);

    /// @dev returns the accounts stack
    function getStack(address account) external view returns (Stack memory);

    /// @dev adds the accounts stack
    function addStack(uint256 count) external returns (Stack memory);

    /// @dev adds the caller all fee tokens to stack
    function addFullStack() external returns (Stack memory);

    /// @dev reves the accounts stack
    function removeStack(uint256 count) external returns (Stack memory);

    /// @dev removes the caller all fee tokens from stack
    function removeFullStack() external returns (Stack memory);

    /// @dev total stacks erc20 count
    function totalStacks() external view returns (uint256);

    /// @dev returns the total fee tokens stacked at current interval
    function totalStacksOnInterval() external view returns (uint256);

    /// @dev returns total eth for rewards
    function ethTotal() external view returns (uint256);

    /// @dev returns total erc20 for rewards
    function erc20Total(address erc20) external view returns (uint256);

    /// @dev returns total eth at current interval
    function ethOnInterval() external view returns (uint256);

    /// @dev returns total erc20 at current interval
    function erc20OnInterval(address erc20) external view returns (uint256);

    /// @dev the interval from which an account can claim ethereum rewards
    /// sets to next interval if add stack or claim eth
    function ethClaimIntervalForAccount(
        address account
    ) external view returns (uint256);

    /// @dev the interval from which an account can claim erc20 rewards
    /// sets to next interval if add stack or claim eth
    function erc20ClaimIntervalForAccount(
        address account,
        address erc20
    ) external view returns (uint256);

    /// @dev returns eth that would be claimed by account at current time
    function ethClaimCountForAccount(
        address account
    ) external view returns (uint256);

    /// @dev returns erc20 that would be claimed by account at current time
    function erc20ClaimCountForAccount(
        address account,
        address erc20
    ) external view returns (uint256);

    /// @dev returns expected eth that would be claimed by account at current time (on all intervals)
    function ethClaimCountForAccountExpect(
        address account
    ) external view returns (uint256);

    /// @dev returns expected erc20 that would be claimed by account at current time (on all intervals)
    function erc20ClaimCountForAccountExpect(
        address account,
        address erc20
    ) external view returns (uint256);

    /// @dev returns expected eth claim count for stack size at current time (on all intervals)
    function ethClaimCountForStackExpect(
        uint256 stackSize
    ) external view returns (uint256);

    /// @dev returns expected erc20 that would be claimed for stack size at current time (on all intervals)
    function erc20ClaimCountForStackExpect(
        uint256 stackSize,
        address erc20
    ) external view returns (uint256);

    /// @dev returns expected eth claim count for new stack size at current time (on all intervals)
    function ethClaimCountForNewStackExpect(
        uint256 stackSize
    ) external view returns (uint256);

    /// @dev returns expected erc20 that would be claimed for new stack size at current time (on all intervals)
    function erc20ClaimCountForNewStackExpect(
        uint256 stackSize,
        address erc20
    ) external view returns (uint256);

    /// @dev returns eth claim count for stack on interval
    function ethClaimCountForStack(
        uint256 stackSize
    ) external view returns (uint256);

    /// @dev returns erc20 that would be claimed for stack size at current time
    function erc20ClaimCountForStack(
        uint256 stackSize,
        address erc20
    ) external view returns (uint256);

    /// @dev claims ethereum
    function claimEth() external;

    /// @dev claims certain erc20
    function claimErc20(address erc20) external;

    /// @dev batch claim ethereum and or erc20 tokens
    function batchClaim(bool claimEth, address[] calldata tokens) external;
}