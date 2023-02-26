//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Datastructures.sol";
import "./Ownable.sol";

abstract contract Core is Ownable, Pausable {
  using Counters for Counters.Counter;

  event UpdateCA(address indexed old, address indexed newCa);

  address public certificationAuthority;
  bytes32 private immutable _THIS_HASH;

  mapping(address => Counters.Counter) private nonces;

  constructor(address owner_, address ca) Ownable(owner_) {
    certificationAuthority = ca;
    _THIS_HASH = keccak256(abi.encode(block.chainid, address(this)));
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function updateCA(address ca) external onlyOwner {
    require(ca != address(0), "Core:ca-must-be-non-zero-address");
    emit UpdateCA(certificationAuthority, ca);
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
    require(
      _blockTimestamp() <= certificate.deadline,
      "Core:expired-certificate"
    );
    bytes32 hash = ECDSA.toEthSignedMessageHash(_message);
    address signer = ECDSA.recover(
      hash,
      certificate.v,
      certificate.r,
      certificate.s
    );

    require(certificationAuthority == signer, "Core:invalid-certificate");
  }

  function _thisHash() internal view returns (bytes32) {
    return _THIS_HASH;
  }
}