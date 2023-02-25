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
// =================== SingleSignEntityStrategy ========================
// =====================================================================

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./interfaces/ISingleSignEntityStrategy.sol";
import { ENTITY_FACTORY_CONTRACT_CODE } from "../Constants.sol";
import "../interfaces/IContractsRegistry.sol";

/**
 * @title SingleSignEntityStrategy
 * @author milestoneBased R&D Team
 *
 * @dev Used to check validity of EIP712-compatible entity signature by a single trusted address.
 */
contract SingleSignEntityStrategy is
  ISingleSignEntityStrategy,
  Ownable,
  EIP712
{
  /**
   * @dev Constanst for stroing typehash of signature container
   */
  bytes32 private constant _ENTITY_TYPEHASH =
    keccak256(
      "Entity(address owner,address entityFactory,uint256 entityType,uint256 id,uint256 nonce,uint256 deadline)"
    );

  /**
   * @dev Variable for storing contractsRegistry address
   */
  IContractsRegistry public contractsRegistry;

  /**
   * @dev Variable for storing trusted signer address
   */
  address public override trustedSigner;

  /**
   * @dev Mapping for storing the used nonces by user address
   */
  mapping(address => mapping(uint256 => bool)) public usedNonces;

  /**
   * @dev Throws if called by any account other than the `entityFactory`
   */
  modifier onlyEntityFactory() {
    if (
      _msgSender() !=
      contractsRegistry.getContractByKey(ENTITY_FACTORY_CONTRACT_CODE)
    ) {
      revert OnlyEntityFactory();
    }
    _;
  }

  /**
   * @dev Initializes the contract setting and owner
   *
   * The caller will become the owner
   *
   * Requirements:
   *
   * - All parameters be not equal ZERO_ADDRESS
   */
  constructor(address contractsRegistry_, address trustedSigner_)
    EIP712("SingleSignEntityStrategy", "v1")
  {
    if (trustedSigner_ == address(0) || contractsRegistry_ == address(0)) {
      revert ZeroAddress();
    }
    trustedSigner = trustedSigner_;
    contractsRegistry = IContractsRegistry(contractsRegistry_);
  }

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
  function setTrustedSigner(address trustedSigner_) external onlyOwner {
    if (trustedSigner_ == address(0)) {
      revert ZeroAddress();
    }
    trustedSigner = trustedSigner_;
    emit TrustedSignerChanged(trustedSigner_);
  }

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
  ) external onlyEntityFactory {
    if (!_isValid(entity_, deadline_, nonce_, v_, r_, s_)) {
      revert InvalidSignature();
    }
    usedNonces[entity_.owner][nonce_] = true;
    emit UsedNonce(entity_.owner, nonce_);
  }

  /**
   * @dev Returns the status whether the (EIP712) signature is valid
   *
   * Returns types:
   * - `false` - signature is invalid
   * - `true` - signature is valid
   */
  function isValid(
    Entity calldata entity_,
    uint256 deadline_,
    uint256 nonce_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external view virtual override returns (bool) {
    return _isValid(entity_, deadline_, nonce_, v_, r_, s_);
  }

  /**
   * @dev Returns the status whether the (EIP712) signature is valid
   *
   * Returns types:
   * - `false` - signature is invalid
   * - `true` - signature is valid
   */
  function _isValid(
    Entity calldata entity_,
    uint256 deadline_,
    uint256 nonce_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) internal view virtual returns (bool) {
    if (usedNonces[entity_.owner][nonce_] || block.timestamp > deadline_) {
      return false;
    }
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          _ENTITY_TYPEHASH,
          entity_.owner,
          entity_.entityFactory,
          entity_.entityType,
          entity_.id,
          nonce_,
          deadline_
        )
      )
    );
    return ECDSA.recover(digest, v_, r_, s_) == trustedSigner;
  }
}