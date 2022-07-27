// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Distributor {
  function distributeTokens(IERC721 _tokenAddress, address[] memory _to, uint256[] memory _tokenId) external {
    require(_to.length <= 255);
    require(_tokenId.length <= 255);

    for (uint8 i = 0; i < _to.length; i++) {
      _tokenAddress.transferFrom(msg.sender, _to[i], _tokenId[i]);
    }
  }
}