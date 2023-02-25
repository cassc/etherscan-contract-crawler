// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

// =====================================================================
//
// |  \/  (_) |         | |                 |  _ \                   | |
// | \  / |_| | ___  ___| |_ ___  _ __   ___| |_) | __ _ ___  ___  __| |
// | |\/| | | |/ _ \/ __| __/ _ \| '_ \ / _ \  _ < / _` / __|/ _ \/ _` |
// | |  | | | |  __/\__ \ || (_) | | | |  __/ |_) | (_| \__ \  __/ (_| |
// |_|  |_|_|_|\___||___/\__\___/|_| |_|\___|____/ \__,_|___/\___|\__,_|
//
// =====================================================================
// ================== ISingleSignEntityStrategy ========================
// =====================================================================

/**
 * @title ISingleSignEntityStrategy
 * @author milestoneBased R&D Team
 *
 * @dev  External interface of `SingleSignEntityStrategy`
 */
interface ISingleSignEntityStrategy {
  /**
   * @dev Throws if a certain field equal ZERO_ADDRESS, which shouldn't be
   */
  error ZeroAddress();

  /**
   * @dev Throws if the sender is not the `entityFactory`.
   */
  error OnlyEntityFactory();

  /**
   * @dev Throws if the provided signature was invalid`.
   */
  error InvalidSignature();

  /**
   * @dev DTO for transfer Entity object for signature check`.
   */
  struct Entity {
    address owner;
    address entityFactory;
    uint256 entityType;
    uint256 id;
  }

  /**
   * @dev Emitted when changed trusted signer address
   */
  event TrustedSignerChanged(address indexed newTrustedSigner);

  /**
   * @dev Emitted when `nonce` marked as used
   */
  event UsedNonce(address indexed user, uint256 indexed nonce);

  /**
   * @dev Update `trustedSigner` address
   *
   * Requirements:
   *
   * - can only be called by owner
   * - `trustedSigner_` must be not equal: `ZERO_ADDRESS`
   *
   * Emit a {TrustedSignerChanged} event.
   */
  function setTrustedSigner(address trustedSigner_) external;

  /**
   * @dev Marking signature as used if signature valid
   *
   * Requirements:
   * - can only be called by the `entityFactory`
   *
   * Throwing if the signature is invalid
   *
   * Emit a {UsedNonce} event.
   */
  function useSignature(
    Entity calldata entity_,
    uint256 deadline_,
    uint256 nonce_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external;

  /**
   * @dev Returns the status whether the (EIP712) signature is valid
   *
   * Returns types:
   * - `false` - signature is valid
   * - `true` - signature is not valid
   */
  function isValid(
    Entity calldata entity_,
    uint256 deadline_,
    uint256 nonce_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external view returns (bool);

  /**
   * @dev Returns the status of `user_` is use `nonce_` or not
   *
   * Returns types:
   * - `false` - if `user_` haven't used `nonce_`
   * - `true` - if `user_` have used `nonce_`
   */
  function usedNonces(address user_, uint256 nonce_)
    external
    view
    returns (bool);

  /**
   * @dev Returns the addresses of the trusted signer.
   */
  function trustedSigner() external view returns (address);
}