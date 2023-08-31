// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "./IButtonswapERC20Errors.sol";
import {IButtonswapERC20Events} from "./IButtonswapERC20Events.sol";

interface IButtonswapERC20 is IButtonswapERC20Errors, IButtonswapERC20Events {
    /**
     * @notice Returns the name of the token.
     * @return _name The token name
     */
    function name() external view returns (string memory _name);

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     * @return _symbol The token symbol
     */
    function symbol() external view returns (string memory _symbol);

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * @dev This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the contract.
     * @return decimals The number of decimals
     */
    function decimals() external pure returns (uint8 decimals);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return totalSupply The amount of tokens in existence
     */
    function totalSupply() external view returns (uint256 totalSupply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param owner The account the balance is being checked for
     * @return balance The amount of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
     * This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @return allowance The amount of tokens owned by `owner` that the `spender` can transfer
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     * @notice Sets `value` as the allowance of `spender` over the caller's tokens.
     * @dev IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     * @param spender The account that is granted permission to spend the tokens
     * @param value The amount of tokens that can be spent
     * @return success Whether the operation succeeded
     */
    function approve(address spender, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from the caller's account to `to`.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transfer(address to, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from `from` to `to` using the allowance mechanism.
     * `value` is then deducted from the caller's allowance.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param from The account that is sending the tokens
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return DOMAIN_SEPARATOR The `DOMAIN_SEPARATOR` value
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 DOMAIN_SEPARATOR);

    /**
     * @notice Returns the typehash used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return PERMIT_TYPEHASH The `PERMIT_TYPEHASH` value
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32 PERMIT_TYPEHASH);

    /**
     * @notice Returns the current nonce for `owner`.
     * This value must be included whenever a signature is generated for {permit}.
     * @dev Every successful call to {permit} increases `owner`'s nonce by one.
     * This prevents a signature from being used multiple times.
     * @param owner The account to get the nonce for
     * @return nonce The current nonce for the given `owner`
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval.
     * @dev IMPORTANT: The same issues {approve} has related to transaction ordering also apply here.
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the [relevant EIP section](https://eips.ethereum.org/EIPS/eip-2612#specification).
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @param value The amount of `owner`'s tokens that `spender` can transfer
     * @param deadline The future time after which the permit is no longer valid
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}