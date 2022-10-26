// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title ERC20 interface.
    @author @farruhsydykov.
 */
interface IERC20 {
    /**
        @dev returns the amount of tokens that currently exist.
     */
    function totalSupply() external view returns (uint256);

    /**
        @dev returns the amount of tokens owned by account.
        @param account is the account which's balance is checked
     */
    function balanceOf(address account) external view returns (uint256);

    /**
        @dev sends caller's tokens to the recipient's account.
        @param recipient account that will recieve tokens in case of transfer success
        @param amount amount of tokens being sent
        @return bool representing success of operation.
        @notice if success emits transfer event
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
        @dev returns the remaining amount of tokens that spender is allowed
        to spend on behalf of owner.
        @param owner is the account which's tokens are allowed to be spent by spender.
        @param spender is the account which is allowed to spend owners tokens.
        @return amount of tokens in uint256 that are allowed to spender.
        @notice allowance value changes when aprove or transferFrom functions are called.
        @notice allowance is zero by default.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
        @dev allowes spender to spend a set amount of caller's tokens throught transferFrom.
        @param spender is the account which will be allowed to spend owners tokens.
        @param amount is the amount of caller's tokens allowed to be spent by spender.
        @return bool representing a success or failure of the function call.
        @notice emits and Approval event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
        @dev sends amount of allowed tokens from the sender's account to recipient'saccount.
        amount is then deducted from the caller's allowance.
        @param sender is the account which's tokens are allowed to and sent by the caller.
        @param recipient is the account which will receive tokens from the sender.
        @param amount is the amount of tokens sent from the sender.
        @return bool representing a success or a failure of transaction.
        @notice emits Transfer event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
        @dev emitted when a transfer occures. Notifies about the value sent from which to which account.
        @param from acccount that sent tokens.
        @param to account that received tokens.
        @param value value sent from sender to receiver.
        @notice value may be zero
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
        @dev emitted when an account allowed another account to spend it's tokens on it's behalf.
        @param owner owner of tokens which allowed it's tokens to be spent.
        @param spender account who was allowed to spend tokens on another's account behalf.
        @param value amount of tokens allowed to spend by spender from owner's account.
        @notice value is always the allowed amount. It does not accumulated with calls to approve.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}