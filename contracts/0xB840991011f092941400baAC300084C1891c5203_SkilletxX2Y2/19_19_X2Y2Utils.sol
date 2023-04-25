//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "./X2Y2AddressProvider.sol";

contract X2Y2Utils is X2Y2AddressProvider {

  function getBorrowerNoteId(
    uint32 loanId
  ) public 
    view 
    returns (uint256 borrowerNoteId)
  {
    borrowerNoteId = uint256(
      uint64(
        uint256(keccak256(abi.encodePacked(addressProvider.getXY3(), loanId)))
      ));
  }
}