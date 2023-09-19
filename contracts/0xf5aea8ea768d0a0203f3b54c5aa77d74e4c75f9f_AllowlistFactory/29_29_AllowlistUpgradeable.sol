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
import "contracts/external/openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "contracts/interfaces/IAllowlist.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

/**
 * @title AllowlistUpgradeable
 * @author Ondo Finance
 * @notice This contract manages the allowlist status for accounts.
 */
contract AllowlistUpgradeable is
  Initializable,
  AccessControlEnumerableUpgradeable,
  IAllowlist
{
  /// @dev Role based access control roles
  bytes32 public constant ALLOWLIST_ADMIN = keccak256("ALLOWLIST_ADMIN");
  bytes32 public constant ALLOWLIST_SETTER = keccak256("ALLOWLIST_SETTER");

  /// @dev {<EOA> : {<term index> : <is verified>}};
  mapping(address => mapping(uint256 => bool)) public verifications;

  string[] public terms;
  uint256 public currentTermIndex = 0;
  uint256[] public validIndexes;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address admin, address setter) public initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(ALLOWLIST_ADMIN, admin);
    _grantRole(ALLOWLIST_SETTER, setter);
  }

  /**
   * @notice Gets a list term indexes that are valid for a user to be on the
   *         allowlist
   */
  function getValidTermIndexes()
    external
    view
    override
    returns (uint256[] memory)
  {
    return validIndexes;
  }

  /**
   * @notice Returns the current terms string associated with the
   *         `currentTermIndex`
   */
  function getCurrentTerm() external view override returns (string memory) {
    return terms[currentTermIndex];
  }

  /**
   * @notice Adds a term to the list of possible terms
   *
   * @param term Term to add
   *
   * @dev This function sets the current term index as the added term
   * @dev The added term is not valid until it's added to validIndexes
   */
  function addTerm(
    string calldata term
  ) external override onlyRole(ALLOWLIST_ADMIN) {
    terms.push(term);
    setCurrentTermIndex(terms.length - 1);
    emit TermAdded(keccak256(bytes(term)), terms.length - 1);
  }

  /**
   * @notice Sets the current term index
   *
   * @param _currentTermIndex New current term index
   *
   * @dev The current term index is not a valid term until it's added to
   *      validIndexes
   * @dev This function will revert if the `_currentTermIndex` out of bounds
   *      of the terms array
   */
  function setCurrentTermIndex(
    uint256 _currentTermIndex
  ) public override onlyRole(ALLOWLIST_ADMIN) {
    if (_currentTermIndex >= terms.length) {
      revert InvalidTermIndex();
    }
    uint256 oldIndex = currentTermIndex;
    currentTermIndex = _currentTermIndex;
    emit CurrentTermIndexSet(oldIndex, _currentTermIndex);
  }

  /**
   * @notice Sets the list of valid term indexes
   *
   * @param _validIndexes List of new valid term indexes
   *
   * @dev Once the validIndexes are set, any user who has been verified to sign
   *      a particular term will pass the `isAllowed` check
   */
  function setValidTermIndexes(
    uint256[] calldata _validIndexes
  ) external override onlyRole(ALLOWLIST_ADMIN) {
    for (uint256 i; i < _validIndexes.length; ++i) {
      if (_validIndexes[i] >= terms.length) {
        revert InvalidTermIndex();
      }
    }
    uint256[] memory oldIndexes = validIndexes;
    validIndexes = _validIndexes;
    emit ValidTermIndexesSet(oldIndexes, _validIndexes);
  }

  /**
   * @notice Function that checks whether a user passes the allowlist check
   *
   * @param account Address of the account to check
   *
   * @dev Contracts are always allowed. Any entity that has signed a valid term
   *      or added themselves to the allowslit for a valid term will pass the
   *      check
   */
  function isAllowed(address account) external view override returns (bool) {
    // Contracts are always allowed
    if (AddressUpgradeable.isContract(account)) {
      return true;
    }

    uint256 validIndexesLength = validIndexes.length;
    for (uint256 i; i < validIndexesLength; ++i) {
      if (verifications[account][validIndexes[i]]) {
        return true;
      }
    }
    return false;
  }

  /**
   * @notice Function that allows a user to add themselves to the allowlist
   *         for a given `termIndex`
   *
   * @param termIndex Term index for which the user is adding themselves to the
   *                  allowlist
   */
  function addSelfToAllowlist(uint256 termIndex) external override {
    if (verifications[msg.sender][termIndex]) {
      revert AlreadyVerified();
    }
    _setAccountStatus(msg.sender, termIndex, true);
    emit AccountAddedSelf(msg.sender, termIndex);
  }

  /**
   * @notice Admin function to set an accounts status for a given term index
   *
   * @param account   Address of the account to set the status for
   * @param termIndex Term index for which to update status for
   * @param status    New status of the account
   *
   * @dev If a user's status has been set to false, a user can then set their
   *      status back to true. This behavior is known. The allowlist should be
   *      used in conjunction with a blocklist
   */
  function setAccountStatus(
    address account,
    uint256 termIndex,
    bool status
  ) external override onlyRole(ALLOWLIST_SETTER) {
    _setAccountStatus(account, termIndex, status);
    emit AccountStatusSetByAdmin(account, termIndex, status);
  }

  /**
   * @notice Function that allows anyone to add a user to the allowlist with a
   *         given off-chain signature
   *
   * @param termIndex Term index for which the user is adding themselves to the
   *                  allowlist
   * @param account   Address of the account to add to the allowlist
   * @param v         v component of the signature
   * @param r         r component of the signature
   * @param s         s component of the signature
   */
  function addAccountToAllowlist(
    uint256 termIndex,
    address account,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    if (verifications[account][termIndex]) {
      revert AlreadyVerified();
    }

    if (v != 27 && v != 28) {
      revert InvalidVSignature();
    }

    bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(
      bytes(terms[termIndex])
    );
    address signer = ECDSA.recover(hashedMessage, v, r, s);

    if (signer != account) {
      revert InvalidSigner();
    }
    _setAccountStatus(account, termIndex, true);
    emit AccountAddedFromSignature(account, termIndex, v, r, s);
  }

  /**
   * @notice Internal function to set the status of an account for a given term
   *
   * @param account   Address of the account to set the status for
   * @param termIndex Term index for which to update status for
   * @param status    New status of the account
   */
  function _setAccountStatus(
    address account,
    uint256 termIndex,
    bool status
  ) internal {
    if (termIndex >= terms.length) {
      revert InvalidTermIndex();
    }
    verifications[account][termIndex] = status;
    emit AccountStatusSet(account, termIndex, status);
  }
}