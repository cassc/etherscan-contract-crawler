//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Shares Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the shares of the depositor and the ERC20 interface
interface ISharesManagerV1 is IERC20 {
    /// @notice Emitted when the total supply is changed
    event SetTotalSupply(uint256 totalSupply);

    /// @notice Balance too low to perform operation
    error BalanceTooLow();

    /// @notice Allowance too low to perform operation
    /// @param _from Account where funds are sent from
    /// @param _operator Account attempting the transfer
    /// @param _allowance Current allowance
    /// @param _value Requested transfer value in shares
    error AllowanceTooLow(address _from, address _operator, uint256 _allowance, uint256 _value);

    /// @notice Invalid empty transfer
    error NullTransfer();

    /// @notice Invalid transfer recipients
    /// @param _from Account sending the funds in the invalid transfer
    /// @param _to Account receiving the funds in the invalid transfer
    error UnauthorizedTransfer(address _from, address _to);

    /// @notice Retrieve the token name
    /// @return The token name
    function name() external pure returns (string memory);

    /// @notice Retrieve the token symbol
    /// @return The token symbol
    function symbol() external pure returns (string memory);

    /// @notice Retrieve the decimal count
    /// @return The decimal count
    function decimals() external pure returns (uint8);

    /// @notice Retrieve the total token supply
    /// @return The total supply in shares
    function totalSupply() external view returns (uint256);

    /// @notice Retrieve the total underlying asset supply
    /// @return The total underlying asset supply
    function totalUnderlyingSupply() external view returns (uint256);

    /// @notice Retrieve the balance of an account
    /// @param _owner Address to be checked
    /// @return The balance of the account in shares
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance of an account
    /// @param _owner Address to be checked
    /// @return The underlying balance of the account
    function balanceOfUnderlying(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance from an amount of shares
    /// @param _shares Amount of shares to convert
    /// @return The underlying asset balance represented by the shares
    function underlyingBalanceFromShares(uint256 _shares) external view returns (uint256);

    /// @notice Retrieve the shares count from an underlying asset amount
    /// @param _underlyingAssetAmount Amount of underlying asset to convert
    /// @return The amount of shares worth the underlying asset amopunt
    function sharesFromUnderlyingBalance(uint256 _underlyingAssetAmount) external view returns (uint256);

    /// @notice Retrieve the allowance value for a spender
    /// @param _owner Address that issued the allowance
    /// @param _spender Address that received the allowance
    /// @return The allowance in shares for a given spender
    function allowance(address _owner, address _spender) external view returns (uint256);

    /// @notice Performs a transfer from the message sender to the provided account
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @notice Performs a transfer between two recipients
    /// @param _from Address sending the tokens
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /// @notice Approves an account for future spendings
    /// @dev An approved account can use transferFrom to transfer funds on behalf of the token owner
    /// @param _spender Address that is allowed to spend the tokens
    /// @param _value The allowed amount in shares, will override previous value
    /// @return True if success
    function approve(address _spender, uint256 _value) external returns (bool);

    /// @notice Increase allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _additionalValue Amount of shares to add
    /// @return True if success
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool);

    /// @notice Decrease allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _subtractableValue Amount of shares to subtract
    /// @return True if success
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool);
}