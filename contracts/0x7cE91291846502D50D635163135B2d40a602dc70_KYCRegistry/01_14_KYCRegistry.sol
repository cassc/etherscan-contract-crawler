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

import "contracts/interfaces/IKYCRegistry.sol";
import "contracts/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/external/chainalysis/ISanctionsList.sol";
import "contracts/external/openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "contracts/external/openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title KYCRegistry
 * @author Ondo Finance
 * @notice This contract manages KYC status for addresses that interact with
 *         Ondo products.
 */
contract KYCRegistry is AccessControlEnumerable, IKYCRegistry, EIP712 {
  bytes32 public constant _APPROVAL_TYPEHASH =
    keccak256(
      "KYCApproval(uint256 kycRequirementGroup,address user,uint256 deadline)"
    );
  // Admin role that has permission to add/remove KYC related roles
  bytes32 public constant REGISTRY_ADMIN = keccak256("REGISTRY_ADMIN");

  // {<KYCLevel> => {<user account address> => is user KYC approved}
  mapping(uint256 => mapping(address => bool)) public kycState;

  // Represents which roles msg.sender must have in order to change
  // KYC state at that group.
  /// @dev Default admin role of 0x00... will be able to set all group roles
  ///      that are unset.
  mapping(uint256 => bytes32) public kycGroupRoles;

  // Chainalysis sanctions list
  ISanctionsList public immutable sanctionsList;

  /// @notice constructor
  constructor(
    address admin,
    address _sanctionsList
  ) EIP712("OndoKYCRegistry", "1") {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(REGISTRY_ADMIN, admin);
    sanctionsList = ISanctionsList(_sanctionsList);
  }

  /**
   * @notice Add a provided user to the registry at a specified
   *         `kycRequirementGroup`. In order to sucessfully call this function,
   *         An external caller must provide a signature signed by an address
   *         with the role `kycGroupRoles[kycRequirementGroup]`.
   *
   * @param kycRequirementGroup KYC requirement group to modify `user`'s
   *                            KYC status for
   * @param user                User address to change KYC status for
   * @param deadline            Deadline for which the signature-auth based
   *                            operations with the signature become invalid
   * @param v                   Recovery ID (See EIP 155)
   * @param r                   Part of ECDSA signature representation
   * @param s                   Part of ECDSA signature representation
   *
   * @dev Please note that ecrecover (which the Registry uses) requires V be
   *      27 or 28, so a conversion must be applied before interacting with
   *      `addKYCAddressViaSignature`
   */
  function addKYCAddressViaSignature(
    uint256 kycRequirementGroup,
    address user,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(v == 27 || v == 28, "KYCRegistry: invalid v value in signature");
    require(
      !kycState[kycRequirementGroup][user],
      "KYCRegistry: user already verified"
    );
    require(block.timestamp <= deadline, "KYCRegistry: signature expired");
    bytes32 structHash = keccak256(
      abi.encode(_APPROVAL_TYPEHASH, kycRequirementGroup, user, deadline)
    );
    // https://eips.ethereum.org/EIPS/eip-712 compliant
    bytes32 expectedMessage = _hashTypedDataV4(structHash);

    // `ECDSA.recover` reverts if signer is address(0)
    address signer = ECDSA.recover(expectedMessage, v, r, s);
    _checkRole(kycGroupRoles[kycRequirementGroup], signer);

    kycState[kycRequirementGroup][user] = true;

    emit KYCAddressAddViaSignature(
      msg.sender,
      user,
      signer,
      kycRequirementGroup,
      deadline
    );
  }

  /// @notice Getter for EIP 712 Domain separator.
  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }

  /**
   * @notice Get KYC status of `account` for the provided
   *         `kycRequirementGroup`. In order to return true, `account`'s state
   *         in this contract must be true and additionally pass a
   *         `sanctionsList` check.
   *
   * @param kycRequirementGroup KYC group to check KYC status for
   * @param account             Addresses to check KYC status for
   */
  function getKYCStatus(
    uint256 kycRequirementGroup,
    address account
  ) external view override returns (bool) {
    return
      kycState[kycRequirementGroup][account] &&
      !sanctionsList.isSanctioned(account);
  }

  /**
   * @notice Assigns a role to specified `kycRequirementGroup` to gate changes
   *         to that group's KYC state
   *
   * @param kycRequirementGroup KYC group to set role for
   * @param role                The role being assigned to a group
   */
  function assignRoletoKYCGroup(
    uint256 kycRequirementGroup,
    bytes32 role
  ) external onlyRole(REGISTRY_ADMIN) {
    kycGroupRoles[kycRequirementGroup] = role;
    emit RoleAssignedToKYCGroup(kycRequirementGroup, role);
  }

  /**
   * @notice Add addresses to KYC list for specified `kycRequirementGroup`
   *
   * @param kycRequirementGroup KYC group associated with `addresses`
   * @param addresses           List of addresses to grant KYC'd status
   */
  function addKYCAddresses(
    uint256 kycRequirementGroup,
    address[] calldata addresses
  ) external onlyRole(kycGroupRoles[kycRequirementGroup]) {
    uint256 length = addresses.length;
    for (uint256 i = 0; i < length; i++) {
      kycState[kycRequirementGroup][addresses[i]] = true;
    }
    emit KYCAddressesAdded(msg.sender, kycRequirementGroup, addresses);
  }

  /**
   * @notice Remove addresses from KYC list
   *
   * @param kycRequirementGroup KYC group associated with `addresses`
   * @param addresses           List of addresses to revoke KYC'd status
   */
  function removeKYCAddresses(
    uint256 kycRequirementGroup,
    address[] calldata addresses
  ) external onlyRole(kycGroupRoles[kycRequirementGroup]) {
    uint256 length = addresses.length;
    for (uint256 i = 0; i < length; i++) {
      kycState[kycRequirementGroup][addresses[i]] = false;
    }
    emit KYCAddressesRemoved(msg.sender, kycRequirementGroup, addresses);
  }

  /*//////////////////////////////////////////////////////////////
                        Events
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Event emitted when a role is assigned to a KYC group
   *
   * @param kycRequirementGroup The KYC group
   * @param role                The role being assigned
   */
  event RoleAssignedToKYCGroup(
    uint256 indexed kycRequirementGroup,
    bytes32 indexed role
  );

  /**
   * @dev Event emitted when addresses are added to KYC requirement group
   *
   * @param sender              Sender of the transaction
   * @param kycRequirementGroup KYC requirement group being updated
   * @param addresses           Array of addresses being added as elligible
   */
  event KYCAddressesAdded(
    address indexed sender,
    uint256 indexed kycRequirementGroup,
    address[] addresses
  );

  /**
   * @dev Event emitted when a user is added to the KYCRegistry
   *      by an external caller through signature-auth
   *
   * @param sender              Sender of the transaction
   * @param user                User being added to registry
   * @param signer              Digest signer
   * @param kycRequirementGroup KYC requirement group being updated
   * @param deadline            Expiration constraint on signature
   */
  event KYCAddressAddViaSignature(
    address indexed sender,
    address indexed user,
    address indexed signer,
    uint256 kycRequirementGroup,
    uint256 deadline
  );

  /**
   * @dev Event emitted when addresses are removed from KYC requirement group
   *
   * @param sender              Sender of the transaction
   * @param kycRequirementGroup KYC requirement group being updated
   * @param addresses           Array of addresses being added as elligible
   */
  event KYCAddressesRemoved(
    address indexed sender,
    uint256 indexed kycRequirementGroup,
    address[] addresses
  );
}