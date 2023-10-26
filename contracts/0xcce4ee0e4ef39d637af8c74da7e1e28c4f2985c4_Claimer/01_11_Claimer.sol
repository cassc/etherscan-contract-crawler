// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ECDSA} from 'oz/utils/cryptography/ECDSA.sol';
import {ClientTokenStore} from './ClientTokenStore.sol';
import {Ownable} from 'oz/access/Ownable.sol';
import {IClaimer} from './interfaces/IClaimer.sol';

contract Claimer is IClaimer, Ownable {
  using ECDSA for bytes32;
  address public systemAddress;
  mapping(uint256 => bool) public usedNonces;

  constructor(address _systemAddress) {
    systemAddress = _systemAddress;
  }

  function getSystemAddress() external view returns (address) {
    return systemAddress;
  }

  function setSystemAddress(
    address _address
  ) external onlyOwner {
    systemAddress = _address;
  }

  function invalidateNonce(
    uint _nonce
  ) internal {
    usedNonces[_nonce] = true;
  }

  function isValidNonce(
    uint _nonce
  ) public view returns (bool) {
    return !usedNonces[_nonce];
  }

  function isValidSignature(
    bytes32 hash,
    bytes memory signature
  ) internal view returns (bool) {
    require(systemAddress != address(0), 'Missing System Address');
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == systemAddress;
  }

  function claim(
    address _recipient,
    address _token,
    address _tokenStore,
    uint _amount,
    uint _nonce,
    uint _deadline,
    bytes memory _signature
  ) external {
    require(block.timestamp <= _deadline, 'Deadline has passed');
    require(msg.sender == _recipient, 'Sender must be recipient');
    require(isValidNonce(_nonce), 'Nonce already used');

    bytes32 hash = keccak256(abi.encodePacked(
      msg.sender, // use to make sure sender is recipient in the signed tx
      _token,
      _tokenStore,
      _amount,
      _nonce,
      _deadline
    ));

    require(isValidSignature(hash, _signature), 'Invalid Signature');
    ClientTokenStore(_tokenStore).withdrawToReceiver(_recipient, _token, _amount);
    invalidateNonce(_nonce);
    emit Claim(_recipient, _token, _tokenStore, _amount, _nonce);
  }
}