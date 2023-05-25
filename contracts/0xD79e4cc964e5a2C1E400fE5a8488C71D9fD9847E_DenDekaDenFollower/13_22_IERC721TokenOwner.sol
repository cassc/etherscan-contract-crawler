pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0



interface IERC721TokenOwner {

  error NotTokenOwner();

  function ownerOf(uint256 tokenId) external view returns (address);
}