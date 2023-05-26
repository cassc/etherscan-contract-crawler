// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ---  External Libraries  --- */
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

/* ---  Proxy Contracts  --- */
import { CodeHashes } from "./CodeHashes.sol";


/**
 * @dev Library for computing create2 salts and addresses for proxies
 * deployed by `DelegateCallProxyManager`.
 *
 * Because the proxy factory is meant to be used by multiple contracts,
 * we use a salt derivation pattern that includes the address of the
 * contract that requested the proxy deployment, a salt provided by that
 * contract and the implementation ID used (for many-to-one proxies only).
 */
library SaltyLib {
/* ---  Salt Derivation  --- */

  /**
   * @dev Derives the create2 salt for a many-to-one proxy.
   *
   * Many different contracts in the Indexed framework may use the
   * same implementation contract, and they all use the same init
   * code, so we derive the actual create2 salt from a combination
   * of the implementation ID, the address of the account requesting
   * deployment and the user-supplied salt.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveManyToOneSalt(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        originator,
        implementationID,
        suppliedSalt
      )
    );
  }

  /**
   * @dev Derives the create2 salt for a one-to-one proxy.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveOneToOneSalt(
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(originator, suppliedSalt));
  }

/* ---  Address Derivation  --- */

  /**
   * @dev Computes the create2 address for a one-to-one proxy deployed
   * by `deployer` (the factory) when requested by `originator` using
   * `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address deployer,
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` deployed by `deployer` (the factory)
   * when requested by `originator` using `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address deployer,
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param deployer Address of the proxy factory.
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(
    address deployer,
    bytes32 implementationID
  )
    internal
    pure
    returns (address)
  {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH,
      deployer
    );
  }
}