// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignedSecret is Ownable{
  using ECDSA for bytes32;

  address internal _signer;
  string internal _secret;

  constructor( address signer, string memory secret ){
    setSignedConfig( signer, secret );
  }

  function setSignedConfig( address signer, string memory secret ) public onlyOwner{
    _signer = signer;
    _secret = secret;
  }

  function _createHash( string memory data ) internal virtual view returns ( bytes32 ){
    return keccak256( abi.encodePacked( address(this), msg.sender, data, _secret ) );
  }

  function _isAuthorizedSigner( string memory data, bytes calldata signature ) internal view virtual returns( bool ){
    return _signer == _recoverSigner( _createHash( data ), signature );
  }

  function _recoverSigner( bytes32 hashed, bytes memory signature ) internal pure returns( address ){
    return hashed.toEthSignedMessageHash().recover( signature );
  }
}