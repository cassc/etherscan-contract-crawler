// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// LightLink 2022

abstract contract BaseControl is Ownable {

  // variables
  bool public presaleActive;
  bool public saleActive;
  bool public tokenPaused;

  address public tearContract;
  address public signerAccount = 0x046c2c915d899D550471d0a7b4d0FaCF79Cde290;
  string public hashKey = "vhils-drp";

  string public backupURI;
  string public defaultURI;

  function togglePresale(bool _status) external onlyOwner {
    presaleActive = _status;
  }

  function toggleSale(bool _status) external onlyOwner {
    saleActive = _status;
  }

  function setTokenPaused(bool _status) external onlyOwner {
    tokenPaused = _status;
  }

  function setSignerInfo(address _signer) external onlyOwner {
    signerAccount = _signer;
  }

  function setHashKey(string calldata _hashKey) external onlyOwner {
    hashKey = _hashKey;
  }

  function setTearContract(address _contract) external onlyOwner {
    tearContract = _contract;
  }

  function setBackupURI(string calldata _uri) external onlyOwner {
    backupURI = _uri;
  }

  function setDefaultURI(string calldata _uri) external onlyOwner {
    defaultURI = _uri;
  }

  /** Internal */
  function isBlank(string memory _string) internal pure returns (bool) {
    return bytes(_string).length == 0;
  }

  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  function validSignature(bytes32 _message, bytes memory _signature) internal view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == signerAccount;
  }
}