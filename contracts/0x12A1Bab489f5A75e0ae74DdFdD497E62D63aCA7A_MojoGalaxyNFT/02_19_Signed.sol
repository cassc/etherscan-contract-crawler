// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Signed{
  using ECDSA for bytes32;

  address internal _signer;

  constructor( address signer ){
    _setSigner( signer );
  }

  function _createHash( bytes memory data ) internal virtual view returns ( bytes32 ){
    return keccak256( abi.encodePacked( address(this), msg.sender, data ) );
  }

  function _isAuthorizedSigner( bytes memory data, bytes calldata signature ) internal view virtual returns( bool ){
    return _signer == _recoverSigner( _createHash( data ), signature );
  }

  function _recoverSigner( bytes32 hashed, bytes memory signature ) internal pure returns( address ){
    return hashed.toEthSignedMessageHash().recover( signature );
  }

  function _setSigner( address signer ) internal{
    _signer = signer;
  }
}