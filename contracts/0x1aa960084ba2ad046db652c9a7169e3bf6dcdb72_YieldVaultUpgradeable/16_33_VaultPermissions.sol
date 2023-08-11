// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title VaultPermissions
 *
 * @author Fujidao Labs
 *
 * @notice An abstract contract intended to be inherited by tokenized vaults, that
 * allow users to modify allowance of a withdraw and/or borrow amount by signing a
 * structured data {EIP712} message.
 * This implementation is inspired by EIP2612 used for `ERC20-permit()`.
 * The use of `permitBorrow()` and `permitWithdraw()` allows for third party contracts
 * or "operators" to perform actions on behalf users across chains.
 */

import {IVaultPermissions} from "../interfaces/IVaultPermissions.sol";
import {EIP712} from "../abstracts/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";

contract VaultPermissions is IVaultPermissions, EIP712 {
  using Counters for Counters.Counter;

  /// @dev Custom Errors
  error VaultPermissions__zeroAddress();
  error VaultPermissions__expiredDeadline();
  error VaultPermissions__invalidSignature();
  error VaultPermissions__insufficientWithdrawAllowance();
  error VaultPermissions__insufficientBorrowAllowance();
  error VaultPermissions__allowanceBelowZero();

  /// @dev Allowance mapping structure: owner => operator => receiver => amount.
  mapping(address => mapping(address => mapping(address => uint256))) internal _withdrawAllowance;
  mapping(address => mapping(address => mapping(address => uint256))) internal _borrowAllowance;

  mapping(address => Counters.Counter) private _nonces;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 private constant PERMIT_WITHDRAW_TYPEHASH = keccak256(
    "PermitWithdraw(uint256 destChainId,address owner,address operator,address receiver,uint256 amount,uint256 nonce,uint256 deadline,bytes32 actionArgsHash)"
  );
  // solhint-disable-next-line var-name-mixedcase
  bytes32 private constant PERMIT_BORROW_TYPEHASH = keccak256(
    "PermitBorrow(uint256 destChainId,address owner,address operator,address receiver,uint256 amount,uint256 nonce,uint256 deadline,bytes32 actionArgsHash)"
  );

  /// @dev Reserve a slot as recommended in OZ {draft-ERC20Permit}.
  // solhint-disable-next-line var-name-mixedcase
  bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

  /// @inheritdoc IVaultPermissions
  function withdrawAllowance(
    address owner,
    address operator,
    address receiver
  )
    public
    view
    override
    returns (uint256)
  {
    return _withdrawAllowance[owner][operator][receiver];
  }

  /// @inheritdoc IVaultPermissions
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _borrowAllowance[owner][operator][receiver];
  }

  /// @inheritdoc IVaultPermissions
  function increaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    override
    returns (bool)
  {
    address owner = msg.sender;
    _setWithdrawAllowance(
      owner, operator, receiver, _withdrawAllowance[owner][operator][receiver] + byAmount
    );
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function decreaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    override
    returns (bool)
  {
    address owner = msg.sender;
    uint256 currentAllowance = _withdrawAllowance[owner][operator][receiver];
    if (byAmount > currentAllowance) {
      revert VaultPermissions__allowanceBelowZero();
    }
    unchecked {
      _setWithdrawAllowance(owner, operator, receiver, currentAllowance - byAmount);
    }
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    address owner = msg.sender;
    _setBorrowAllowance(
      owner, operator, receiver, _borrowAllowance[owner][operator][receiver] + byAmount
    );
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    address owner = msg.sender;
    uint256 currentAllowance = _borrowAllowance[owner][operator][receiver];
    if (byAmount > currentAllowance) {
      revert VaultPermissions__allowanceBelowZero();
    }
    unchecked {
      _setBorrowAllowance(owner, operator, receiver, currentAllowance - byAmount);
    }
    return true;
  }

  /// @inheritdoc IVaultPermissions
  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner].current();
  }

  /// @inheritdoc IVaultPermissions
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }

  /// @inheritdoc IVaultPermissions
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
    public
    override
  {
    _checkDeadline(deadline);
    address operator = msg.sender;
    bytes32 structHash;
    // Scoped code to avoid "Stack too deep"
    {
      bytes memory data;
      uint256 currentNonce = _useNonce(owner);
      {
        data = abi.encode(
          PERMIT_WITHDRAW_TYPEHASH,
          block.chainid,
          owner,
          operator,
          receiver,
          amount,
          currentNonce,
          deadline,
          actionArgsHash
        );
      }
      structHash = keccak256(data);
    }

    _checkSigner(structHash, owner, v, r, s);

    _setWithdrawAllowance(owner, operator, receiver, amount);
  }

  /// @inheritdoc IVaultPermissions
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
    public
    virtual
    override
  {
    _checkDeadline(deadline);
    address operator = msg.sender;
    bytes32 structHash;
    // Scoped code to avoid "Stack too deep"
    {
      bytes memory data;
      uint256 currentNonce = _useNonce(owner);
      {
        data = abi.encode(
          PERMIT_BORROW_TYPEHASH,
          block.chainid,
          owner,
          operator,
          receiver,
          amount,
          currentNonce,
          deadline,
          actionArgsHash
        );
      }
      structHash = keccak256(data);
    }

    _checkSigner(structHash, owner, v, r, s);

    _setBorrowAllowance(owner, operator, receiver, amount);
  }

  /// Internal Functions

  /**
   * @dev Sets assets `amount` as the allowance of `operator` over the `owner`'s assets.
   * This internal function is equivalent to `approve`.
   * Requirements:
   * - Must only be used in `asset` withdrawal logic.
   * - Must check `owner` cannot be the zero address.
   * - Much check `operator` cannot be the zero address.
   * - Must emits an {WithdrawApproval} event.
   *
   * @param owner address who is providing `withdrawAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   *
   */
  function _setWithdrawAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
  {
    if (owner == address(0) || operator == address(0) || receiver == address(0)) {
      revert VaultPermissions__zeroAddress();
    }
    _withdrawAllowance[owner][operator][receiver] = amount;
    emit WithdrawApproval(owner, operator, receiver, amount);
  }

  /**
   * @dev Sets `amount` as the borrow allowance of `operator` over the `owner`'s debt.
   * This internal function is equivalent to `approve` for debt.
   * Requirements:
   * - Must  only be used in `debtAsset` borrowing logic.
   * - Must check `owner` cannot be the zero address.
   * - Much check `operator` cannot be the zero address.
   * - Must emit an {BorrowApproval} event.
   *
   * @param owner address who is providing `borrowAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   *
   */
  function _setBorrowAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
  {
    if (owner == address(0) || operator == address(0) || receiver == address(0)) {
      revert VaultPermissions__zeroAddress();
    }
    _borrowAllowance[owner][operator][receiver] = amount;
    emit BorrowApproval(owner, operator, receiver, amount);
  }

  /**
   * @dev Spends `withdrawAllowance`.
   * Based on OZ {ERC20-spendAllowance} for {BaseVault-assets}.
   *
   * @param owner address who is spending `withdrawAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   */
  function _spendWithdrawAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
  {
    uint256 currentAllowance = withdrawAllowance(owner, operator, receiver);
    if (currentAllowance != type(uint256).max) {
      if (amount > currentAllowance) {
        revert VaultPermissions__insufficientWithdrawAllowance();
      }
      unchecked {
        // Enforce to never leave unused allowance, unless allowance set to type(uint256).max
        _setWithdrawAllowance(owner, operator, receiver, 0);
      }
    }
  }

  /**
   * @dev Spends 'borrowAllowance`.
   * Based on OZ {ERC20-spendAllowance} for assets.
   *
   * @param owner address who is spending `borrowAllowance`
   * @param operator address who is allowed to operate the allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   */
  function _spendBorrowAllowance(
    address owner,
    address operator,
    address receiver,
    uint256 amount
  )
    internal
    virtual
  {
    uint256 currentAllowance = _borrowAllowance[owner][operator][receiver];
    if (currentAllowance != type(uint256).max) {
      if (amount > currentAllowance) {
        revert VaultPermissions__insufficientBorrowAllowance();
      }
      unchecked {
        // Enforce to never leave unused allowance, unless allowance set to type(uint256).max
        _setBorrowAllowance(owner, operator, receiver, 0);
      }
    }
  }

  /**
   * @dev "Consume a nonce": return the current amount and increment.
   * _Available since v4.1._
   *
   * @param owner address who uses a permit
   */
  function _useNonce(address owner) internal returns (uint256 current) {
    Counters.Counter storage nonce = _nonces[owner];
    current = nonce.current();
    nonce.increment();
  }

  /**
   * @dev Reverts if block.timestamp is expired according to `deadline`.
   *
   * @param deadline timestamp to check
   */
  function _checkDeadline(uint256 deadline) private view {
    if (block.timestamp > deadline) {
      revert VaultPermissions__expiredDeadline();
    }
  }

  /**
   * @dev Reverts if `presumedOwner` is not signer of `structHash`.
   *
   * @param structHash of data
   * @param presumedOwner address to check
   * @param v signature value
   * @param r signautre value
   * @param s signature value
   */
  function _checkSigner(
    bytes32 structHash,
    address presumedOwner,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    internal
    view
  {
    bytes32 digest = _hashTypedDataV4(structHash);
    address signer = ECDSA.recover(digest, v, r, s);
    if (signer != presumedOwner) {
      revert VaultPermissions__invalidSignature();
    }
  }
}