// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ISignatureVerifier.sol";

/// @dev modify from https://etherscan.io/address/0xde1e6a7ed0ad3f61d531a8a78e83ccddbd6e0c49
contract VoteProxy is Ownable {
  ISignatureVerifier public verifier;

  function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4) {
    // Validate signatures
    if (verifier.verifySignature(_hash, _signature) == true) {
      return 0x1626ba7e;
    } else {
      return 0xffffffff;
    }
  }

  function updateVerifier(address _verifier) public onlyOwner {
    verifier = ISignatureVerifier(_verifier);
  }

  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external onlyOwner returns (bool, bytes memory) {
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }
}