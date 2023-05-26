// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @title ERC-20 Multi Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-20
*/
interface IERC20 /* is IERC165 */ {
  /**
  * @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}.
  *   `value` is the new allowance.
  * 
  * @param owner address that owns the tokens
  * @param spender address allowed to spend the tokens
  * @param value the amount of tokens allowed to be spent
  */
  event Approval(address indexed owner, address indexed spender, uint256 value);
  /**
  * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
  *   Note that `value` may be zero.
  * 
  * @param from address tokens are being transferred from
  * @param to address tokens are being transferred to
  * @param value amount of tokens being transferred
  */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
  * @dev Sets `amount_` as the allowance of `spender_` over the caller's tokens.
  *
  * Returns a boolean value indicating whether the operation succeeded.
  *
  * IMPORTANT: Beware that changing an allowance with this method brings the risk
  *   that someone may use both the old and the new allowance by unfortunate transaction ordering.
  *   One possible solution to mitigate this race condition is to first reduce the spender"s allowance to 0,
  *   and set the desired value afterwards:
  *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  *
  * Emits an {Approval} event.
  */
  function approve(address spender_, uint256 amount_) external returns (bool);
  /**
  * @dev Moves `amount_` tokens from the caller's account to `recipient_`.
  *
  * Returns a boolean value indicating whether the operation succeeded.
  *
  * Emits a {Transfer} event.
  */
  function transfer(address recipient_, uint256 amount_) external returns (bool);
  /**
  * @dev Moves `amount_` tokens from `sender_` to `recipient_` using the allowance mechanism.
  *   `amount_` is then deducted from the caller's allowance.
  *
  * Returns a boolean value indicating whether the operation succeeded.
  *
  * Emits a {Transfer} event.
  */
  function transferFrom(
    address sender_,
    address recipient_,
    uint256 amount_
  ) external returns (bool);

  /**
  * @dev Returns the remaining number of tokens that `spender_` will be allowed to spend on behalf of `owner_`
  *   through {transferFrom}. This is zero by default.
  *
  * This value changes when {approve} or {transferFrom} are called.
  */
  function allowance(address owner_, address spender_) external view returns (uint256);
  /**
  * @dev Returns the amount of tokens owned by `account_`.
  */
  function balanceOf(address account_) external view returns (uint256);
  /**
  * @dev Returns the amount of tokens in existence.
  */
  function totalSupply() external view returns (uint256);
}