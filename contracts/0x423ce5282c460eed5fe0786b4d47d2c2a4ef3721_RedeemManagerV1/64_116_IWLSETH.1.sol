//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Wrapped LsETH Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to wrap the LsETH token into a rebase token.
interface IWLSETHV1 {
    /// @notice A transfer has been made
    /// @param from The transfer sender
    /// @param to The transfer recipient
    /// @param value The amount transfered
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice An approval has been made
    /// @param owner The token owner
    /// @param spender The account allowed by the owner
    /// @param value The amount allowed
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Tokens have been minted
    /// @param recipient The account receiving the new tokens
    /// @param shares The amount of LsETH provided
    event Mint(address indexed recipient, uint256 shares);

    /// @notice Tokens have been burned
    /// @param recipient The account that receive the underlying LsETH
    /// @param shares The amount of LsETH that got sent back
    event Burn(address indexed recipient, uint256 shares);

    /// @notice The stored value of river has been changed
    /// @param river The new address of river
    event SetRiver(address indexed river);

    /// @notice The token transfer failed during the minting or burning process
    error TokenTransferError();

    /// @notice Balance too low to perform operation
    error BalanceTooLow();

    /// @notice Allowance too low to perform operation
    /// @param _from Account where funds are sent from
    /// @param _operator Account attempting the transfer
    /// @param _allowance Current allowance
    /// @param _value Requested transfer value
    error AllowanceTooLow(address _from, address _operator, uint256 _allowance, uint256 _value);

    /// @notice Invalid empty transfer
    error NullTransfer();

    /// @notice Invalid transfer recipients
    /// @param _from Account sending the funds in the invalid transfer
    /// @param _to Account receiving the funds in the invalid transfer
    error UnauthorizedTransfer(address _from, address _to);

    /// @notice Initializes the wrapped token contract
    /// @param _river Address of the River contract
    function initWLSETHV1(address _river) external;

    /// @notice Retrieves the token full name
    /// @return The name of the token
    function name() external pure returns (string memory);

    /// @notice Retrieves the token symbol
    /// @return The symbol of the token
    function symbol() external pure returns (string memory);

    /// @notice Retrieves the token decimal count
    /// @return The decimal count
    function decimals() external pure returns (uint8);

    /// @notice Retrieves the token total supply
    /// @return The total supply
    function totalSupply() external view returns (uint256);

    /// @notice Retrieves the token balance of the specified user
    /// @param _owner Owner to check the balance
    /// @return The balance of the owner
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Retrieves the raw shares count of the user
    /// @param _owner Owner to check the shares balance
    /// @return The shares of the owner
    function sharesOf(address _owner) external view returns (uint256);

    /// @notice Retrieves the token allowance given from one address to another
    /// @param _owner Owner that gave the allowance
    /// @param _spender Spender that received the allowance
    /// @return The allowance of the owner to the spender
    function allowance(address _owner, address _spender) external view returns (uint256);

    /// @notice Transfers tokens between the message sender and a recipient
    /// @param _to Recipient of the transfer
    /// @param _value Amount to transfer
    /// @return True if success
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @notice Transfers tokens between two accounts
    /// @dev It is expected that _from has given at least _value allowance to msg.sender
    /// @param _from Sender account
    /// @param _to Recipient of the transfer
    /// @param _value Amount to transfer
    /// @return True if success
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /// @notice Approves another account to transfer tokens
    /// @param _spender Spender that receives the allowance
    /// @param _value Amount to allow
    /// @return True if success
    function approve(address _spender, uint256 _value) external returns (bool);

    /// @notice Increase allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _additionalValue Amount to add
    /// @return True if success
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool);

    /// @notice Decrease allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _subtractableValue Amount to subtract
    /// @return True if success
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool);

    /// @notice Mint tokens by providing LsETH tokens
    /// @dev The message sender locks LsETH tokens and received wrapped LsETH tokens in exchange
    /// @dev The message sender needs to approve the contract to mint the wrapped tokens
    /// @dev The minted wrapped LsETH is sent to the specified recipient
    /// @param _recipient The account receiving the new minted wrapped LsETH
    /// @param _shares The amount of LsETH to wrap
    function mint(address _recipient, uint256 _shares) external;

    /// @notice Burn tokens and retrieve underlying LsETH tokens
    /// @dev The message sender burns shares from its balance for the LsETH equivalent value
    /// @dev The message sender doesn't need to approve the contract to burn the shares
    /// @dev The freed LsETH is sent to the specified recipient
    /// @param _recipient The account receiving the underlying LsETH tokens after shares are burned
    /// @param _shares Amount of LsETH to free by burning wrapped LsETH
    function burn(address _recipient, uint256 _shares) external;
}