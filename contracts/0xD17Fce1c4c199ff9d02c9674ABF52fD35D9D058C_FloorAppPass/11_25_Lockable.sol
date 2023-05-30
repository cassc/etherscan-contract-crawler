// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

error ContractLocked();
error InvalidDestructCode();

abstract contract Lockable is Ownable {

  bool public contractIsLocked = false;

  // Recognize voice pattern Jean-Luc Picard, authorization Alpha-Alpha 3-0-5
  string private DESTRUCT_CODE = "aa305";

  function lockContract(string memory _destructCode) external onlyOwner {
    if(!_isEqual(_destructCode, DESTRUCT_CODE)) revert InvalidDestructCode();

    contractIsLocked = true;
  }

  function _isEqual(string memory s1, string memory s2) private pure returns (bool) {
    bytes memory b1 = bytes(s1);
    bytes memory b2 = bytes(s2);
    uint256 l1 = b1.length;

    if (l1 != b2.length) return false;

    for (uint256 i=0; i<l1; i++) {
      if (b1[i] != b2[i]) return false;
    }
    return true;
  }

  modifier requireActiveContract {
    if(contractIsLocked) revert ContractLocked();
    _;
  }
}