//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../lib/IERC1271.sol';

contract SignatureChecker is Ownable {
  using ECDSA for bytes32;
  using Address for address;
  bool public checkSignatureFlag;

  bytes4 internal constant _INTERFACE_ID_ERC1271 = 0x1626ba7e;
  bytes4 internal constant _ERC1271FAILVALUE = 0xffffffff;

  function setCheckSignatureFlag(bool _newFlag) public onlyOwner {
    checkSignatureFlag = _newFlag;
  }

  function getSigner(bytes32 _signedHash, bytes memory _signature) public pure returns (address) {
    return _signedHash.toEthSignedMessageHash().recover(_signature);
  }

  function checkSignature(
    bytes32 _signedHash,
    bytes memory _signature,
    address _checkAddress
  ) public view returns (bool) {
    if (_checkAddress.isContract()) {
      return IERC1271(_checkAddress).isValidSignature(_signedHash, _signature) == _INTERFACE_ID_ERC1271;
    } else {
      return getSigner(_signedHash, _signature) == _checkAddress;
    }
  }
}