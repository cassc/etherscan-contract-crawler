// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IWETH.sol";
import "../library/Transfer.sol";
import "../interfaces/SignatureConsumer.sol";
import "../interfaces/MappedTokenConsumer.sol";

interface IMainchainGatewayV2 is SignatureConsumer, MappedTokenConsumer {
  /// @dev Emitted when the deposit is requested
  event DepositRequested(bytes32 receiptHash, Transfer.Receipt receipt);
  /// @dev Emitted when the assets are withdrawn
  event Withdrew(bytes32 receiptHash, Transfer.Receipt receipt);
  /// @dev Emitted when the tokens are mapped
  event TokenMapped(address[] mainchainTokens, address[] roninTokens, Token.Standard[] standards);
  /// @dev Emitted when the wrapped native token contract is updated
  event WrappedNativeTokenContractUpdated(IWETH weth);
  /// @dev Emitted when the withdrawal is locked
  event WithdrawalLocked(bytes32 receiptHash, Transfer.Receipt receipt);
  /// @dev Emitted when the withdrawal is unlocked
  event WithdrawalUnlocked(bytes32 receiptHash, Transfer.Receipt receipt);

  /**
   * @dev Returns the domain seperator.
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @dev Returns deposit count.
   */
  function depositCount() external view returns (uint256);

  /**
   * @dev Sets the wrapped native token contract.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits the `WrappedNativeTokenContractUpdated` event.
   *
   */
  function setWrappedNativeTokenContract(IWETH _wrappedToken) external;

  /**
   * @dev Returns whether the withdrawal is locked.
   */
  function withdrawalLocked(uint256 withdrawalId) external view returns (bool);

  /**
   * @dev Returns the withdrawal hash.
   */
  function withdrawalHash(uint256 withdrawalId) external view returns (bytes32);

  /**
   * @dev Locks the assets and request deposit.
   */
  function requestDepositFor(Transfer.Request calldata _request) external payable;

  /**
   * @dev Withdraws based on the receipt and the validator signatures.
   * Returns whether the withdrawal is locked.
   *
   * Emits the `Withdrew` once the assets are released.
   *
   */
  function submitWithdrawal(Transfer.Receipt memory _receipt, Signature[] memory _signatures)
    external
    returns (bool _locked);

  /**
   * @dev Approves a specific withdrawal.
   *
   * Requirements:
   * - The method caller is a validator.
   *
   * Emits the `Withdrew` once the assets are released.
   *
   */
  function unlockWithdrawal(Transfer.Receipt calldata _receipt) external;

  /**
   * @dev Maps mainchain tokens to Ronin network.
   *
   * Requirement:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `TokenMapped` event.
   *
   */
  function mapTokens(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards
  ) external;

  /**
   * @dev Maps mainchain tokens to Ronin network and sets thresholds.
   *
   * Requirement:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `TokenMapped` event.
   *
   */
  function mapTokensAndThresholds(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards,
    uint256[][4] calldata _thresholds
  ) external;

  /**
   * @dev Returns token address on Ronin network.
   * @notice Reverts for unsupported token.
   */
  function getRoninToken(address _mainchainToken) external view returns (MappedToken memory _token);
}