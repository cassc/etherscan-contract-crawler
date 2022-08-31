// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721Batch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool );
  function safeTransferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external;
  function transferBatch( address from, address to, uint[] calldata tokenIds ) external;
  function walletOfOwner( address account ) external view returns( uint[] memory );
}