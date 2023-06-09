// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./FreezableRoot.sol";
import "./Revocable.sol";
import "./SignatureLib.sol";

abstract contract TxValidatable is ContextUpgradeable, EIP712Upgradeable, FreezableRoot, Revocable {
  using MerkleProofUpgradeable for bytes32[];
  using SignatureCheckerUpgradeable for address;

  function _validateTx(
    address signer,
    bytes32 hash,
    SignatureLib.SignatureData memory signatureData
  ) internal view returns (bool, string memory) {
    (bool isHashValid, string memory hashErrorMessage) = _validateHash(hash);
    if (!isHashValid) {
      return (false, hashErrorMessage);
    }
    (bool isRootValid, string memory rootErrorMessage) = _validateRoot(signatureData.root);
    if (!isRootValid) {
      return (false, rootErrorMessage);
    }

    if (!signatureData.proof.verify(signatureData.root, hash)) {
      return (false, "TxValidatable: proof verification failed");
    }

    if (signatureData.signature.length == 0) {
      address sender = _msgSender();
      if (signer != sender) {
        return (false, "TxValidatable: sender verification failed");
      }
    } else {
      if (
        !signer.isValidSignatureNow(_hashTypedDataV4(SignatureLib.hashStruct(signatureData)), signatureData.signature)
      ) {
        if (!signer.isValidSignatureNow(_hashTypedDataV4(hash), signatureData.signature)) {
          return (false, "TxValidatable: signature verification failed");
        }
      }
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}