// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ECDSA.sol";

// Based on OpenZeppelin's draft EIP712, with updates to remove storage variables.

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 */
library EIP712 {
  bytes32 private constant _TYPE_HASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

  /**
   * @dev Returns the domain separator for the current chain.
   */
  function domainSeparatorV4(string memory name, string memory version)
    internal
    view
    returns (bytes32)
  {
    return
      _buildDomainSeparator(
        _TYPE_HASH,
        keccak256(bytes(name)),
        keccak256(bytes(version))
      );
  }

  function _buildDomainSeparator(
    bytes32 typeHash,
    bytes32 name,
    bytes32 version
  ) private view returns (bytes32) {
    uint256 chainId;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
    return
      keccak256(abi.encode(typeHash, name, version, chainId, address(this)));
  }

  /**
   * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
   * function returns the hash of the fully encoded EIP712 message for the given domain.
   *
   * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
   *
   * ```solidity
   * bytes32 digest = EIP712.hashTypedDataV4(
   *   EIP712.domainSeparatorV4("DApp Name", "1"),
   *   keccak256(abi.encode(
   *     keccak256("Mail(address to,string contents)"),
   *     mailTo,
   *     keccak256(bytes(mailContents))
   * )));
   * address signer = ECDSA.recover(digest, signature);
   * ```
   */
  function hashTypedDataV4(bytes32 domainSeparator, bytes32 structHash)
    internal
    pure
    returns (bytes32)
  {
    return ECDSA.toTypedDataHash(domainSeparator, structHash);
  }
}