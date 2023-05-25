// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Allowance
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0xd5b86388.
 */
interface IERC20Allowance {
    /**
     * Increases the allowance granted by the sender to `spender` by `value`.
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described in {IERC20-approve}.
     * @dev Reverts if `spender` is the zero address.
     * @dev Reverts if `spender`'s allowance overflows.
     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.
     * @param spender The account whose allowance is being increased by the message caller.
     * @param value The allowance amount increase.
     * @return True if the allowance increase succeeds, false otherwise.
     */
    function increaseAllowance(address spender, uint256 value) external returns (bool);

    /**
     * Decreases the allowance granted by the sender to `spender` by `value`.
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described in {IERC20-approve}.
     * @dev Reverts if `spender` is the zero address.
     * @dev Reverts if `spender` has an allowance with the message caller for less than `value`.
     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.
     * @param spender The account whose allowance is being decreased by the message caller.
     * @param value The allowance amount decrease.
     * @return True if the allowance decrease succeeds, false otherwise.
     */
    function decreaseAllowance(address spender, uint256 value) external returns (bool);
}