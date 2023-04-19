// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BulkNFTTransfer {
  error InvalidArrayLength();

  function bulkTransfer(
    address[] memory _to,
    uint256[][] memory _tokenIds,
    address _contractAddress
  ) public {
    if (_to.length != _tokenIds.length) {
      revert InvalidArrayLength();
    }
    for (uint256 i = 0; i < _to.length; i++) {
      for (uint256 j = 0; j < _tokenIds[i].length; j++) {
        IERC721(_contractAddress).transferFrom(
          msg.sender,
          _to[i],
          _tokenIds[i][j]
        );
      }
    }
  }
}