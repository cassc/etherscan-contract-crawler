// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * Note: The ERC-165 identifier for this interface is 0x36372b07.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to` via the approval mechanism.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}