// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Delegated.sol";

contract Signed{
  // is Delegated{
  // is IERC1271{
  using ECDSA for bytes32;

  address internal _signer;

  constructor(address signer) {
    _setSigner( signer );
  }

  function _createHash(bytes memory data) internal virtual view returns (bytes32) {
    return keccak256( abi.encodePacked( address(this), msg.sender, data ) );
  }

  function _getSigner(bytes32 hash, bytes memory signature) internal pure returns(address){
    return hash.toEthSignedMessageHash().recover( signature );
  }

  function _isAuthorizedSigner(address extracted) internal view virtual returns(bool){
    return extracted == _signer;
  }

  function _setSigner(address signer) internal{
    _signer = signer;
  }

  function _verifySignature(bytes memory data, bytes memory signature) internal view returns(bool){
    address extracted = _getSigner( _createHash( data ), signature );
    return _isAuthorizedSigner(extracted);
  }
}