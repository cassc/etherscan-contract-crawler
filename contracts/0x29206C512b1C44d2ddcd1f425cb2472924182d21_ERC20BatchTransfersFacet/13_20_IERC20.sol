// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, basic interface.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
interface IERC20 {
    /// @notice Emitted when tokens are transferred, including zero value transfers.
    /// @param from The account where the transferred tokens are withdrawn from.
    /// @param to The account where the transferred tokens are deposited to.
    /// @param value The amount of tokens being transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when an approval is set.
    /// @param owner The account granting an allowance to `spender`.
    /// @param spender The account being granted an allowance from `owner`.
    /// @param value The allowance amount being granted.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Sets the allowance to an account from the sender.
    /// @notice Warning: Beware that changing an allowance with this method brings the risk that someone may use both the old and
    ///  the new allowance by unfortunate transaction ordering. One possible solution to mitigate this race condition is to first reduce
    ///  the spender's allowance to 0 and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Emits an {Approval} event.
    /// @param spender The account being granted the allowance by the message caller.
    /// @param value The allowance amount to grant.
    /// @return result Whether the operation succeeded.
    function approve(address spender, uint256 value) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from the sender.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @return result Whether the operation succeeded.
    function transfer(address to, uint256 value) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from a specified address.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @return result Whether the operation succeeded.
    function transferFrom(address from, address to, uint256 value) external returns (bool result);

    /// @notice Gets the total token supply.
    /// @return supply The total token supply.
    function totalSupply() external view returns (uint256 supply);

    /// @notice Gets an account balance.
    /// @param owner The account whose balance will be returned.
    /// @return balance The account balance.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Gets the amount that an account is allowed to spend on behalf of another.
    /// @param owner The account that has granted an allowance to `spender`.
    /// @param spender The account that was granted an allowance by `owner`.
    /// @return value The amount which `spender` is allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 value);
}