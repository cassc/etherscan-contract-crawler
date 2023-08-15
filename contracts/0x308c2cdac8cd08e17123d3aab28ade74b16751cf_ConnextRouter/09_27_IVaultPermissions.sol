// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IVaultPermissions
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface for a vault extended with
 * signed permit operations for `withdraw()` and `borrow()` allowance.
 */

interface IVaultPermissions {
  /**
   * @dev Emitted when `asset` withdraw allowance is set.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance given
   */
  event WithdrawApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /**
   * @dev Emitted when `debtAsset` borrow allowance is set.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance given
   */
  event BorrowApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /// @dev Based on {IERC20Permit-DOMAIN_SEPARATOR}.
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external returns (bytes32);

  /**
   * @notice Returns the current amount of withdraw allowance from `owner` to `receiver` that
   * can be executed by `operator`. This is similar to {IERC20-allowance} for BaseVault assets,
   * instead of token-shares.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   *
   * @dev Requirements:
   * - Must replace {IERC4626-allowance} in a vault implementation.
   */
  function withdrawAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @notice Returns the current amount of borrow allowance from `owner` to `receiver` that
   * can be executed by `operator`. This is similar to {IERC20-allowance} for
   * BaseVault-debtAsset.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   */
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @dev Atomically increases the `withdrawAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-increaseAllowance} for assets.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to increase withdraw allowance
   *
   * @dev Requirements:
   * - Must emit a {WithdrawApproval} event indicating the updated withdraw allowance.
   * - Must check `operator` and `receiver are not zero address.
   */
  function increaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decreases the `withdrawAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-decreaseAllowance} for assets.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to decrease withdraw allowance
   *
   * @dev Requirements:
   * - Must emit a {WithdrawApproval} event indicating the updated withdraw allowance.
   * - Must check `operator` and `receiver` are not zero address.
   * - Must check `operator` and `receiver` have `borrowAllowance` of at least `byAmount`.
   *
   */
  function decreaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically increases the `borrowAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-increaseAllowance}
   * for `debtAsset`.
   *
   * @param operator address who can execute the use of the allowance
   * @param receiver address who can spend the allowance
   * @param byAmount to increase borrow allowance
   *
   * @dev Requirements:
   * - Must emit a {BorrowApproval} event indicating the updated borrow allowance.
   * - Must check `operator` and `receiver` are not zero address.
   */
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decrease the `borrowAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-decreaseAllowance}
   * for `debtAsset`.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to decrease borrow allowance
   *
   * Requirements:
   * - Must emit a {BorrowApproval} event indicating the updated borrow allowance.
   * - Must check `operator` and `receiver` are not the zero address.
   * - Must check `operator` and `receiver` have `borrowAllowance` of at least `byAmount`.
   */
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @notice Returns the curent used nonces for permits of `owner`.
   * Based on OZ {IERC20Permit-nonces}.
   *
   * @param owner address to check nonces
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Sets `amount` as the `withdrawAllowance` of `receiver` executable by
   * caller over `owner`'s tokens, given the `owner`'s signed approval.
   * Inspired by {IERC20Permit-permit} for assets.
   *
   * @param owner providing allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance
   * @param deadline timestamp limit for the execution of signed permit
   * @param actionArgsHash keccak256 of the abi.encoded(args,actions) to be performed in {BaseRouter._internalBundle}
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must check `deadline` is a timestamp in the future.
   * - Must check `receiver` is a non-zero address.
   * - Must check that `v`, `r` and `s` are valid `secp256k1` signature for `owner`
   *   over EIP712-formatted function arguments.
   * - Must check the signature used `owner`'s current nonce (see {nonces}).
   * - Must emits an {AssetsApproval} event.
   */
  function permitWithdraw(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    bytes32 actionArgsHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;

  /**
   * @notice Sets `amount` as the `borrowAllowance` of `receiver` executable by caller over
   * `owner`'s borrowing powwer, given the `owner`'s signed approval.
   * Inspired by {IERC20Permit-permit} for debt.
   *
   * @param owner address providing allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   * @param deadline timestamp limit for the execution of signed permit
   * @param actionArgsHash keccak256 of the abi.encoded(args,actions) to be performed in {BaseRouter._internalBundle}
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must emit a {BorrowApproval} event.
   * - Must be implemented in a {BorrowingVault}.
   * - Must check `deadline` is a timestamp in the future.
   * - Must check `receiver` is a non-zero address.
   * - Must check that `v`, `r` and `s` are valid `secp256k1` signature for `owner`.
   *   over EIP712-formatted function arguments.
   * - Must check the signature used `owner`'s current nonce (see {nonces}).
   */
  function permitBorrow(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    bytes32 actionArgsHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;
}