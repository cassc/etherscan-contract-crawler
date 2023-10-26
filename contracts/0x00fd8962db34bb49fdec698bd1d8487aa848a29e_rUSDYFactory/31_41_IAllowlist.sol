/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

interface IAllowlist {
  function addTerm(string calldata term) external;

  function setCurrentTermIndex(uint256 _currentTermIndex) external;

  function setValidTermIndexes(uint256[] calldata indexes) external;

  function isAllowed(address account) external view returns (bool);

  function getCurrentTerm() external view returns (string memory);

  function currentTermIndex() external view returns (uint256);

  function getValidTermIndexes() external view returns (uint256[] memory);

  function addAccountToAllowlist(
    uint256 _currentTermIndex,
    address account,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function addSelfToAllowlist(uint256 termIndex) external;

  function setAccountStatus(
    address account,
    uint256 termIndex,
    bool status
  ) external;

  /**
   * @notice Event emitted when a term is added
   *
   * @param hashedMessage The hash of the terms string that was added
   * @param termIndex     The index of the term that was added
   */
  event TermAdded(bytes32 hashedMessage, uint256 termIndex);

  /**
   * @notice Event emitted when the current term index is set
   *
   * @param oldIndex The old current term index
   * @param newIndex The new current term index
   */
  event CurrentTermIndexSet(uint256 oldIndex, uint256 newIndex);

  /**
   * @notice Event emitted when the valid term indexes are set
   *
   * @param oldIndexes The old valid term indexes
   * @param newIndexes The new valid term indexes
   */
  event ValidTermIndexesSet(uint256[] oldIndexes, uint256[] newIndexes);

  /**
   * @notice Event emitted when an accoun status is set by an admin
   *
   * @param account   The account whose status was set
   * @param termIndex The term index of the account whose status that was set
   * @param status    The new status of the account
   */
  event AccountStatusSetByAdmin(
    address indexed account,
    uint256 indexed termIndex,
    bool status
  );

  /**
   * @notice Event emitted when an account adds itself added to the allowlist
   *
   * @param account   The account that was added
   * @param termIndex The term index for which the account was added
   */
  event AccountAddedSelf(address indexed account, uint256 indexed termIndex);

  /**
   * @notice Event emitted when an account is added to the allowlist by a signature
   *
   * @param account   The account that was added
   * @param termIndex The term index for which the account was added
   * @param v         The v value of the signature
   * @param r         The r value of the signature
   * @param s         The s value of the signature
   */
  event AccountAddedFromSignature(
    address indexed account,
    uint256 indexed termIndex,
    uint8 v,
    bytes32 r,
    bytes32 s
  );

  /**
   * @notice Event emitted when an account status is set
   *
   * @param account   The account whose status was set
   * @param termIndex The term index of the account whose status was set
   * @param status    The new status of the account
   */
  event AccountStatusSet(
    address indexed account,
    uint256 indexed termIndex,
    bool status
  );

  /// ERRORS ///
  error InvalidTermIndex();
  error InvalidVSignature();
  error AlreadyVerified();
  error InvalidSigner();
}