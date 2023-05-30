// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface IBatch {
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool );
  function transferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external;
  function walletOfOwner( address account ) external view returns( uint[] memory );
}