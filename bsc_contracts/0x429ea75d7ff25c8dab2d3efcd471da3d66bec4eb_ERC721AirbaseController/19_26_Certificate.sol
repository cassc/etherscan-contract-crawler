//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import "./Datastructures.sol";

abstract contract Certificate {
  using Counters for Counters.Counter;

  address public certificationAuthority;

  mapping(address => Counters.Counter) private nonces;

  constructor(address ca) {
    certificationAuthority = ca;
  }

  /**
   * @dev Returns the current nonce for `ca`. This value must be
   * included whenever a signature is generated.
   *
   * Every successful call to {create, withdraw, withdrawRemaining, claim} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function getNonce(address user) public view virtual returns (uint256) {
    return nonces[user].current();
  }

  function _blockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  /**
   * @dev "Consume a nonce": return the current value and increment.
   *
   */
  function _useNonce(address user) internal virtual returns (uint256 current) {
    Counters.Counter storage nonce = nonces[user];
    current = nonce.current();
    nonce.increment();
  }

  function _validateCertificate(
    bytes memory _message,
    Datastructures.CertificateInfo calldata certificate
  ) internal view virtual {
    console.logBytes(_message);
    console.logUint(certificate.deadline);
    console.logBytes32(certificate.s);
    console.logBytes32(certificate.r);
    console.logUint(certificate.v);
    console.logUint(_blockTimestamp());
    require(
      _blockTimestamp() <= certificate.deadline,
      "Certificate:EXPIRED-DEADLINE"
    );

    bytes32 hash = ECDSA.toEthSignedMessageHash(_message);
    address signer = ECDSA.recover(
      hash,
      certificate.v,
      certificate.r,
      certificate.s
    );

    require(
      certificationAuthority == signer,
      "Certificate:INVALID-CERTIFICATE"
    );
  }
}