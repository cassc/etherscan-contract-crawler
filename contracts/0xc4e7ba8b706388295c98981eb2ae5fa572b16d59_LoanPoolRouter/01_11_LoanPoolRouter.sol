// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../interfaces/ILoanPoolRouter.sol";

/// @title LoanPoolRouter
/// @author Bluejay Core Team
/// @notice LoanPoolRouter routes user funds into different loan pool. It serves as a
/// single point for funding loan pool and keeps a record of all pools funded by a user.
/// @dev Users' loan pool are not held in custody of this contract.
contract LoanPoolRouter is ILoanPoolRouter, EIP712 {
  using SafeERC20 for IERC20;
  using BitMaps for BitMaps.BitMap;

  string private constant EIP712_NAME = "Loan Pool Router";
  string private constant EIP712_REVISION = "1";
  bytes32 private constant PERMIT_TYPEHASH =
    keccak256(
      "Permit(address loanPool,address recipient,uint256 amount,uint256 nonce,uint256 deadline,uint256 salt)"
    );

  /// @notice Nonce for fundLoanPoolWithPermit to allow users to cancel permits
  mapping(address => uint256) public override permitNonce;

  /// @notice Mapping of a permit nullifier to a boolean to check if the permit has been used
  BitMaps.BitMap private permitNullifier;

  /// @dev Initializes the {EIP712} domain separator and cache the DOMAIN_SEPARATOR
  constructor() EIP712(EIP712_NAME, EIP712_REVISION) {}

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Funds a loan pool
  /// @dev The function assumes the loan pool to be valid to reduce gas costs
  /// Applications executing this function should perform additional checks.
  /// @param loanPool Address of the loan pool to be funded
  /// @param amount Amount of funds to be deposited, in funding asset decimal
  /// @param recipient Address where loan token is credited to
  function fundLoanPool(
    ILoanPool loanPool,
    uint256 amount,
    address recipient
  ) external override {
    _fundLoanPool(msg.sender, loanPool, amount, recipient);
  }

  /// @notice Funds a loan pool with permit to allow for sponsored transactions
  /// @dev The function assumes the loan pool to be valid to reduce gas costs
  /// Applications executing this function should perform additional checks.
  /// The lender will still have to approve tokens to the router which can be
  /// sponsored using EIP2612 as well.
  /// @param lender Address of the lender where funds are pulled from
  /// @param loanPool Address of the loan pool to be funded
  /// @param amount Amount of funds to be deposited, in funding asset decimal
  /// @param recipient Address where loan token is credited to
  /// @param deadline Deadline where the permit expires
  /// @param salt Random number to make the permit unique
  /// @param v Signature parameter
  /// @param r Signature parameter
  /// @param s Signature parameter
  function fundLoanPoolWithPermit(
    address lender,
    ILoanPool loanPool,
    uint256 amount,
    address recipient,
    uint256 deadline,
    uint256 salt,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    if (deadline < block.timestamp) revert PermitExpired();

    bytes32 structHash = keccak256(
      abi.encode(
        PERMIT_TYPEHASH,
        loanPool,
        recipient,
        amount,
        permitNonce[lender],
        deadline,
        salt
      )
    );
    bytes32 hash = _hashTypedDataV4(structHash);

    if (permitNullifier.get(uint256(structHash))) revert PermitUsed();
    permitNullifier.set(uint256(structHash));

    address signer = ecrecover(hash, v, r, s);
    if (signer != lender) revert InvalidSignature();

    _fundLoanPool(lender, loanPool, amount, recipient);
  }

  /// @notice Cancels all previously signed permits of previous nonce
  function cancelPermit() external override {
    permitNonce[msg.sender] = permitNonce[msg.sender] + 1;
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Returns the DOMAIN_SEPARATOR used for EIP712 signatures
  /// @return separator The domain separator value
  function domainSeparator()
    external
    view
    override
    returns (bytes32 separator)
  {
    return _domainSeparatorV4();
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function for funding a loan pool
  /// @param lender Address of the lender where funds are pulled from
  /// @param loanPool Address of the loan pool to be funded
  /// @param amount Amount of funds to be deposited, in funding asset decimal
  /// @param recipient Address where loan token is credited to
  function _fundLoanPool(
    address lender,
    ILoanPool loanPool,
    uint256 amount,
    address recipient
  ) internal {
    IERC20 fundingAsset = loanPool.fundingAsset();
    fundingAsset.safeTransferFrom(lender, address(loanPool), amount);
    loanPool.fundDangerous(recipient);
    emit LoanPoolFunded(address(loanPool), lender, recipient, amount);
  }
}