//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./EIP712Base.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EIP712MetaTransaction is EIP712Base {
  using SafeMath for uint256;

  event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);

  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));
  mapping(address => uint256) private nonces;

  constructor(string memory name) EIP712Base(name) {}

  function convertBytesToBytes4(
    bytes memory inBytes
  ) internal pure returns (bytes4 outBytes4) {
    if (inBytes.length == 0) {
      return 0x0;
    }

    assembly {
      outBytes4 := mload(add(inBytes, 32))
    }
  }

  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable returns(bytes memory) {
    bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
    require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
    MetaTransaction memory metaTx = MetaTransaction({
      nonce: nonces[userAddress],
      from: userAddress,
      functionSignature: functionSignature
    });
    require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
    nonces[userAddress] = nonces[userAddress].add(1);
    // Append userAddress at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

    require(success, "Function call not successful");
    emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
    return returnData;
  }

  function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
    return keccak256(abi.encode(
      META_TRANSACTION_TYPEHASH,
      metaTx.nonce,
      metaTx.from,
      keccak256(metaTx.functionSignature)
    ));
  }

  function getNonce(address user) external view returns(uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
    address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
    require(signer != address(0), "Invalid signature");
    return signer == user;
  }

  function msgSender() internal view returns(address sender) {
    if(msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }
}