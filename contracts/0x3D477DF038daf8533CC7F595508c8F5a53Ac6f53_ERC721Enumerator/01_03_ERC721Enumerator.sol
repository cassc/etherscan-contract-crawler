// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

library ERC721Enumerator {
  function tokens(address tokenAddress, address owner) external view returns (uint256[] memory) {
    IERC721 tokenContract = IERC721(tokenAddress);

    uint256 balance = tokenContract.balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](balance);

    uint256 offset;
    for (uint256 i; offset < balance; ++i) {
      try tokenContract.ownerOf(i) returns (address tokenOwner) {
        if (tokenOwner == owner) {
          tokenIds[offset] = i;
          ++offset;
        }
      } catch {}
    }

    return tokenIds;
  }
}