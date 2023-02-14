// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IKochiInvest.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// hardhat tools
// DEV ENVIRONMENT ONLY
// import "hardhat/console.sol";

abstract contract Verifiable is ReentrancyGuardUpgradeable {
  address signer; //0x52e4589601c6a2831Cc9EC0565d9A6eaD6a6489F (USEFUL FOR TEST AGAINST config.json)
  event SignerModified(address indexed sender, address signer);

  mapping(bytes => bool) private usedSignatures;

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    require(sig.length == 65, "Invalid signature length.  Must be 65!");

    assembly {
      r := mload(add(sig, 32)) // first 32 bytes, after the length prefix
      s := mload(add(sig, 64)) // second 32 bytes
      v := byte(0, mload(add(sig, 96))) // final byte (first byte of the next 32 bytes)
    }
  }

  function getMessageHash(bytes memory _data) internal pure returns (bytes32) {
    return keccak256(_data);
  }

  function getEthSignedMessageHash(bytes32 message_hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message_hash));
  }

  function recoverSigner(bytes32 eth_signed_message_hash, bytes memory _signature) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
    return ecrecover(eth_signed_message_hash, v, r, s);
  }

  // make sure the data is signed by the backend
  modifier verify(IKochiInvest.SVerify memory verification) {
    require(signer != address(0), "Signer not set: cannot verify signature. Please contact an Administrator."); // CVS-01
    require(getMessageHash(verification.encoded_message) == verification.message_hash, "The message hash doesn't match the original!");

    bytes32 ethSignedMessageHash = getEthSignedMessageHash(verification.message_hash);
    address recoveredSigner = recoverSigner(ethSignedMessageHash, verification.signature);

    require(recoveredSigner == signer, "Invalid signature!");
    require(recoveredSigner != address(0), "Invalid signer!"); // CVS-01
    require(!usedSignatures[verification.signature], "Signature already used!");

    _;

    usedSignatures[verification.signature] = true;
  }
}