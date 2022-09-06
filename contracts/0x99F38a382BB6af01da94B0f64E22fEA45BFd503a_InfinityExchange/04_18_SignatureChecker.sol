// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';

// import 'hardhat/console.sol'; // todo: remove this

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
  /**
   * @notice Recovers the signer of a signature (for EOA)
   * @param hashed the hash containing the signed mesage
   * @param r parameter
   * @param s parameter
   * @param v parameter (27 or 28). This prevents malleability since the public key recovery equation has two possible solutions.
   */
  function recover(
    bytes32 hashed,
    bytes32 r,
    bytes32 s,
    uint8 v
  ) internal pure returns (address) {
    // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
    // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
    require(
      uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      'Signature: Invalid s parameter'
    );

    require(v == 27 || v == 28, 'Signature: Invalid v parameter');

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hashed, v, r, s);
    require(signer != address(0), 'Signature: Invalid signer');
    // console.log('Recovered Signer:', signer);
    return signer;
  }

  /**
   * @notice Returns whether the signer matches the signed message
   * @param orderHash the hash containing the signed message
   * @param signer the signer address to confirm message validity
   * @param r parameter
   * @param s parameter
   * @param v parameter (27 or 28) this prevents malleability since the public key recovery equation has two possible solutions
   * @param domainSeparator paramer to prevent signature being executed in other chains and environments
   * @return true --> if valid // false --> if invalid
   */
  function verify(
    bytes32 orderHash,
    address signer,
    bytes32 r,
    bytes32 s,
    uint8 v,
    bytes32 domainSeparator
  ) internal view returns (bool) {
    // \x19\x01 is the standardized encoding prefix
    // https://eips.ethereum.org/EIPS/eip-712#specification
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, orderHash));
    // console.log('digest:');
    // console.logBytes32(digest);
    if (Address.isContract(signer)) {
      // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
      return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
    } else {
      return recover(digest, r, s, v) == signer;
    }
  }
}